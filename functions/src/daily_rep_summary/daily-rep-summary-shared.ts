import { createHash } from 'node:crypto';

import { HttpsError } from 'firebase-functions/v2/https';
import type { DocumentData, Firestore } from 'firebase-admin/firestore';

import {
  extractCitedDataPointCodes,
  findHallucinatedNumberToken,
} from '../shared/citation-validation';
import { membersShareTeam } from '../shared/team-membership';
// Reused as-is rather than copied (AGENTS.md: "Não duplicar... regra") — this
// vocabulary is exactly as relevant to an automatically-*sent* daily digest
// (no human reviews it before it reaches the seller, unlike
// `suggestApproach`'s own editable draft) as it is to a manually-reviewed
// approach suggestion.
import { FORBIDDEN_COMMERCIAL_TERMS } from '../approach_suggestion/approach-suggestion-shared';
import type {
  DailyRepSummaryDataPoint,
  DailyRepSummaryFollowUpHighlight,
  DailyRepSummaryInsightHighlight,
  DailyRepSummaryOrderIssueHighlight,
  DailyRepSummaryPayload,
  DailyRepSummaryReference,
  DailyRepSummaryTargetRisk,
  DailyRepSummaryValidationOutcome,
} from './daily-rep-summary-types';

/**
 * Shared, mostly-pure domain logic for `generateDailyRepSummary`/
 * `getDailyRepSummary` (TASK-188, EPIC-28) — payload assembly, prompt
 * construction, post-generation validation and the RBAC/caching primitives
 * the two callables/scheduled Function orchestrate. Same "shared calculation
 * core, kept separate from the onCall/onSchedule wrapper" shape as
 * `../wallet_summary/wallet-summary-shared.ts` (TASK-186) and
 * `../approach_suggestion/approach-suggestion-shared.ts` (TASK-187).
 */

/** Maximum insights (highest estimated impact first) ever included in one
 * payload — mirrors `WALLET_SUMMARY_MAX_INSIGHTS`. */
export const DAILY_REP_SUMMARY_MAX_INSIGHTS = 8;

/** Maximum rejected orders ever included in one payload, most recent first —
 * mirrors `APPROACH_SUGGESTION_MAX_ORDERS`. */
export const DAILY_REP_SUMMARY_MAX_PROBLEM_ORDERS = 5;

export function dailyRepSummaryDocId(sellerId: string, dateKey: string): string {
  return `${sellerId}_${dateKey}`;
}

export function dailyRepSummaryRef(
  db: Firestore,
  organizationId: string,
  sellerId: string,
  dateKey: string,
) {
  return db
    .collection('organizations')
    .doc(organizationId)
    .collection('dailyRepSummaries')
    .doc(dailyRepSummaryDocId(sellerId, dateKey));
}

/**
 * Deterministic SHA-256 hex digest of a payload's *content* (every field
 * except [DailyRepSummaryPayload.sellerName], display-only) — mirrors
 * `computePayloadHash` in `wallet-summary-shared.ts`/`approach-suggestion-shared.ts`.
 */
export function computePayloadHash(payload: DailyRepSummaryPayload): string {
  const sortedDataPoints = [...payload.dataPoints]
    .map((point) => ({
      code: point.code,
      value: point.value,
      numericValue: point.numericValue ?? null,
      unit: point.unit ?? null,
    }))
    .sort((left, right) => left.code.localeCompare(right.code));
  const problemOrderIds = payload.problemOrders.map((order) => order.orderId).sort();
  const insightIds = payload.insights.map((insight) => insight.insightId).sort();
  const combined = JSON.stringify({
    dateKey: payload.dateKey,
    dataPoints: sortedDataPoints,
    problemOrderIds,
    insightIds,
    hasTargetRisk: payload.targetRisk != null,
  });
  return createHash('sha256').update(combined).digest('hex');
}

/** Whether [payload] has literally nothing notable to summarize today — the
 * gate `generateDailyRepSummary` checks before ever calling an LLM provider
 * or dispatching a notification (`tasks.md`/TASK-188: never fabricate a
 * summary out of nothing). Zero sales today does *not* alone make a payload
 * empty when there is still a target risk, a problem order or an insight to
 * report. */
export function isDailyRepSummaryPayloadEmpty(payload: DailyRepSummaryPayload): boolean {
  const todaysOrderCount = payload.dataPoints.find(
    (point) => point.code === payload.todaysOrderCountDataPointCode,
  )?.numericValue;
  return (
    payload.targetRisk == null &&
    payload.problemOrders.length === 0 &&
    payload.insights.length === 0 &&
    (todaysOrderCount ?? 0) === 0
  );
}

/** Same "manager scoped to their own team" RBAC shape already enforced by
 * `assertCanAccessSellerWallet` (TASK-186)/`assertCanAccessCustomer`
 * (TASK-187) — a daily rep summary is at least as sensitive (revenue, target
 * risk, named customers), so it never uses a looser rule. `OWNER`/`ADMIN` may
 * request any seller's summary; a seller may always request their own;
 * `SALES_MANAGER` only when the target seller shares at least one of the
 * manager's own teams; every other role is denied. */
export async function assertCanAccessDailyRepSummary(params: {
  db: Firestore;
  organizationId: string;
  requesterUid: string;
  requesterRoleName: string;
  sellerId: string;
}): Promise<void> {
  const { db, organizationId, requesterUid, requesterRoleName, sellerId } = params;
  if (requesterUid === sellerId) return;
  if (requesterRoleName === 'OWNER' || requesterRoleName === 'ADMIN') return;

  if (requesterRoleName === 'SALES_MANAGER') {
    const sharesTeam = await membersShareTeam({
      db,
      organizationId,
      uidA: requesterUid,
      uidB: sellerId,
    });
    if (sharesTeam) return;
  }

  throw new HttpsError(
    'permission-denied',
    'Você só pode consultar o resumo diário da sua própria carteira ou da carteira de vendedores da sua equipe.',
  );
}

/**
 * Assembles one seller's {@link DailyRepSummaryPayload} from raw Firestore
 * data already fetched once per **company** by the orchestrator
 * (`generate-daily-rep-summary.ts`) — never a fresh Firestore read per
 * seller, so a company with many sellers costs a handful of company-wide
 * reads, not one query per seller. Kept pure (no Firestore access of its own)
 * so it is fully unit-testable without an Admin SDK instance.
 */
export function buildDailyRepSummaryPayload(params: {
  organizationId: string;
  companyId: string;
  sellerId: string;
  sellerName: string;
  dateKey: string;
  /** `sellerDailyAggregates/{companyId}_{sellerId}_{dateKey}`'s own data, or
   * `undefined` when the seller had no revenue-recognized order today. */
  todaysAggregateData: DocumentData | undefined;
  /** Every `status === 'fresh'` insight for [companyId], regardless of
   * recipient — the orchestrator reads this collection once per company. */
  companyInsightDocs: readonly { id: string; data: DocumentData }[];
  /** Every non-deleted, `rejected` order for [companyId] — the orchestrator
   * reads this collection once per company. */
  companyRejectedOrderDocs: readonly { id: string; data: DocumentData }[];
  /** Resolved display name per `customerId`, for the [companyRejectedOrderDocs]
   * this seller's own rejected orders reference. */
  customerNamesById: ReadonlyMap<string, string>;
}): DailyRepSummaryPayload {
  const {
    organizationId,
    companyId,
    sellerId,
    sellerName,
    dateKey,
    todaysAggregateData,
    companyInsightDocs,
    companyRejectedOrderDocs,
    customerNamesById,
  } = params;

  const dataPoints: DailyRepSummaryDataPoint[] = [];

  const todaysRevenue = numberOrZero(todaysAggregateData?.revenueNet);
  const todaysOrderCount = numberOrZero(todaysAggregateData?.orderCount);
  dataPoints.push({
    code: 'todays_revenue',
    label: 'Vendas de hoje',
    value: todaysRevenue.toFixed(2),
    numericValue: todaysRevenue,
    unit: 'BRL',
  });
  dataPoints.push({
    code: 'todays_order_count',
    label: 'Pedidos de hoje',
    value: `${todaysOrderCount}`,
    numericValue: todaysOrderCount,
  });

  const sellerInsightDocs = companyInsightDocs
    .filter((doc) => doc.data.recipientUserId === sellerId)
    .sort((left, right) => rawImpactScore(right.data) - rawImpactScore(left.data))
    .slice(0, DAILY_REP_SUMMARY_MAX_INSIGHTS);
  const insights = sellerInsightDocs.map((doc) =>
    extractInsightHighlight(doc.id, doc.data, customerNamesById, dataPoints),
  );

  const targetRiskCandidates = companyInsightDocs.filter(
    (doc) => doc.data.sellerId === sellerId && doc.data.type === 'sellerBelowTarget',
  );
  const targetRisk = extractTargetRisk(
    targetRiskCandidates.map((doc) => ({ id: doc.id, data: doc.data })),
    dataPoints,
  );

  const sellerRejectedOrderDocs = companyRejectedOrderDocs.filter(
    (doc) => doc.data.sellerId === sellerId,
  );
  const problemOrders = sellerRejectedOrderDocs
    .slice(0, DAILY_REP_SUMMARY_MAX_PROBLEM_ORDERS)
    .map((doc) => extractOrderIssueHighlight(doc.id, doc.data, customerNamesById, dataPoints));

  const followUpsToday: DailyRepSummaryFollowUpHighlight[] = [];

  return {
    organizationId,
    companyId,
    sellerId,
    sellerName,
    dateKey,
    todaysRevenueDataPointCode: 'todays_revenue',
    todaysOrderCountDataPointCode: 'todays_order_count',
    targetRisk,
    problemOrders,
    insights,
    followUpsToday,
    dataPoints,
  };
}

function extractOrderIssueHighlight(
  orderId: string,
  data: DocumentData,
  customerNamesById: ReadonlyMap<string, string>,
  dataPoints: DailyRepSummaryDataPoint[],
): DailyRepSummaryOrderIssueHighlight {
  const totalAmount = computeOrderTotal(data);
  const totalAmountDataPointCode = `order_${orderId}_total_amount`;
  dataPoints.push({
    code: totalAmountDataPointCode,
    label: `Valor do pedido ${String(data.orderNumber ?? orderId)}`,
    value: totalAmount.toFixed(2),
    numericValue: totalAmount,
    unit: 'BRL',
  });
  const customerId = typeof data.customerId === 'string' ? data.customerId : null;
  const reasonExcerpt =
    typeof data.rejectionReason === 'string' && data.rejectionReason.trim().length > 0
      ? truncate(data.rejectionReason, 240)
      : null;
  return {
    orderId,
    orderNumber: String(data.orderNumber ?? orderId),
    customerName: (customerId != null ? customerNamesById.get(customerId) : null) ?? 'Cliente',
    reasonExcerpt,
    totalAmountDataPointCode,
  };
}

function computeOrderTotal(data: DocumentData): number {
  const items = Array.isArray(data.items) ? data.items : [];
  const itemsSubtotal = items.reduce(
    (sum: number, item: DocumentData) => sum + numberOrZero(item?.subtotal),
    0,
  );
  const shippingAmount = numberOrZero(data.shippingAmount);
  const surchargeAmount = numberOrZero(data.surchargeAmount);
  const discountAmount = numberOrZero(data.discountAmount);
  return itemsSubtotal + shippingAmount + surchargeAmount - discountAmount;
}

function truncate(value: string, maxLength: number): string {
  const trimmed = value.trim();
  if (trimmed.length <= maxLength) return trimmed;
  return `${trimmed.slice(0, maxLength).trim()}…`;
}

function extractInsightHighlight(
  insightId: string,
  data: DocumentData,
  customerNamesById: ReadonlyMap<string, string>,
  dataPoints: DailyRepSummaryDataPoint[],
): DailyRepSummaryInsightHighlight {
  const evidence = Array.isArray(data.evidence) ? data.evidence : [];
  const dataPointCodes: string[] = [];
  evidence.forEach((item: DocumentData, index: number) => {
    if (typeof item?.numericValue !== 'number' || !Number.isFinite(item.numericValue)) {
      return;
    }
    const code = `insight_${insightId}_${item.code ?? index}`;
    dataPoints.push({
      code,
      label: String(item.label ?? item.code ?? 'Evidência'),
      value: String(item.value ?? item.numericValue),
      numericValue: item.numericValue,
      unit: typeof item.unit === 'string' ? item.unit : undefined,
    });
    dataPointCodes.push(code);
  });

  const impactAmount =
    typeof data.estimatedImpact?.amount === 'number' ? data.estimatedImpact.amount : null;
  if (impactAmount != null) {
    const code = `insight_${insightId}_impact_amount`;
    dataPoints.push({
      code,
      label: `Impacto estimado — ${String(data.title ?? insightId)}`,
      value: impactAmount.toFixed(2),
      numericValue: impactAmount,
      unit: 'BRL',
    });
    dataPointCodes.push(code);
  }

  const customerId = typeof data.customerId === 'string' ? data.customerId : null;
  return {
    insightId,
    type: String(data.type ?? 'unknown'),
    title: String(data.title ?? ''),
    description: String(data.description ?? ''),
    severity: String(data.severity ?? 'low'),
    customerId,
    customerName: customerId != null ? (customerNamesById.get(customerId) ?? null) : null,
    dataPointCodes,
  };
}

function extractTargetRisk(
  candidates: readonly { id: string; data: DocumentData }[],
  dataPoints: DailyRepSummaryDataPoint[],
): DailyRepSummaryTargetRisk | null {
  if (candidates.length === 0) return null;
  // Highest estimated impact first — mirrors
  // `wallet-summary-shared.ts`'s `extractTargetRisk` tie-break.
  const sorted = [...candidates].sort(
    (left, right) =>
      numberOrZero(right.data.estimatedImpact?.amount) -
      numberOrZero(left.data.estimatedImpact?.amount),
  );
  const { id: insightId, data } = sorted[0];
  const evidence = Array.isArray(data.evidence) ? data.evidence : [];
  const targetValue = findEvidenceNumericValue(evidence, 'target_value') ?? 0;
  const realizedValue = findEvidenceNumericValue(evidence, 'realized_value') ?? 0;
  const projectedAchievementPercentage =
    findEvidenceNumericValue(evidence, 'projected_achievement_percentage') ?? 0;

  const codePrefix = `target_risk_${insightId}`;
  const targetValueCode = `${codePrefix}_target_value`;
  const realizedValueCode = `${codePrefix}_realized_value`;
  const projectedCode = `${codePrefix}_projected_achievement_percentage`;

  dataPoints.push({
    code: targetValueCode,
    label: 'Meta do período',
    value: targetValue.toFixed(2),
    numericValue: targetValue,
    unit: 'BRL',
  });
  dataPoints.push({
    code: realizedValueCode,
    label: 'Realizado até o momento',
    value: realizedValue.toFixed(2),
    numericValue: realizedValue,
    unit: 'BRL',
  });
  dataPoints.push({
    code: projectedCode,
    label: 'Percentual de atingimento projetado',
    value: projectedAchievementPercentage.toFixed(1),
    numericValue: projectedAchievementPercentage,
    unit: 'percent',
  });

  return {
    insightId,
    title: String(data.title ?? ''),
    description: String(data.description ?? ''),
    targetValue,
    realizedValue,
    projectedAchievementPercentage,
    dataPointCodes: [targetValueCode, realizedValueCode, projectedCode],
  };
}

function findEvidenceNumericValue(evidence: DocumentData[], code: string): number | null {
  const match = evidence.find((item) => item?.code === code);
  return typeof match?.numericValue === 'number' ? match.numericValue : null;
}

/** Same impact scoring `evaluateInsights`/`extractInsightHighlight`'s own
 * ordering already establishes elsewhere (`insight-engine.ts`'s own
 * `impactScore`, `wallet-summary-shared.ts`'s own `impactScore`) — applied
 * here to the *raw* Firestore document (before it is trimmed down to an
 * highlight) so sorting/slicing to
 * {@link DAILY_REP_SUMMARY_MAX_INSIGHTS} happens before the more expensive
 * per-insight data-point extraction below. */
function rawImpactScore(data: DocumentData): number {
  const amount =
    typeof data.estimatedImpact?.amount === 'number' ? data.estimatedImpact.amount : 0;
  const percentage =
    typeof data.estimatedImpact?.percentage === 'number' ? data.estimatedImpact.percentage : 0;
  return amount + percentage * 1000;
}

function numberOrZero(value: unknown): number {
  return typeof value === 'number' && Number.isFinite(value) ? value : 0;
}

/**
 * Builds the fixed prompt template — same "system prompt carries every rule,
 * user prompt carries only already-verified JSON data" contract as
 * `buildWalletSummaryPrompt`/`buildApproachSuggestionPrompt`.
 */
export function buildDailyRepSummaryPrompt(payload: DailyRepSummaryPayload): {
  systemPrompt: string;
  userPrompt: string;
} {
  const systemPrompt = [
    'Você escreve, em português do Brasil, um resumo diário curto e direto para UM vendedor de moda B2B ler pela manhã antes de começar o dia.',
    'Regras obrigatórias, sem exceção:',
    '1. Use exclusivamente os números presentes em "dataPoints". Nunca calcule, estime ou invente qualquer valor numérico que não exista literalmente em "dataPoints".',
    '2. Toda frase que mencionar um número deve terminar com uma citação no formato "[refs: codigo1, codigo2]", usando exatamente os valores de "code" de "dataPoints" ou dos códigos listados em "riscoDeMeta"/"pedidosComProblema"/"insightsAtivos".',
    '3. Nunca mencione, sugira ou dê a entender qualquer desconto, condição de pagamento, preço especial, promoção, cortesia, brinde ou parcelamento especial.',
    '4. Nunca recomende ou determine uma ação comercial específica (o que dizer, o que oferecer) — o resumo é apenas informativo; cada pendência/insight já tem seu próprio link no aplicativo para o vendedor agir.',
    '5. Se não houver dados suficientes para um tópico (ex.: sem pedidos com problema, sem risco de meta, sem insights), simplesmente omita esse tópico, nunca invente um valor para preenchê-lo.',
    '6. Seja objetivo e direto: no máximo 5 frases, tom profissional e motivador.',
  ].join('\n');

  const userPrompt = JSON.stringify(
    {
      vendedor: payload.sellerName,
      data: payload.dateKey,
      dataPoints: payload.dataPoints.map((point) => ({
        code: point.code,
        label: point.label,
        value: point.value,
        unit: point.unit ?? null,
      })),
      riscoDeMeta: payload.targetRisk
        ? {
            titulo: payload.targetRisk.title,
            descricao: payload.targetRisk.description,
            codigosDeReferencia: payload.targetRisk.dataPointCodes,
          }
        : null,
      pedidosComProblema: payload.problemOrders.map((order) => ({
        numero: order.orderNumber,
        cliente: order.customerName,
        motivo: order.reasonExcerpt,
        codigoValorTotal: order.totalAmountDataPointCode,
      })),
      insightsAtivos: payload.insights.map((insight) => ({
        tipo: insight.type,
        titulo: insight.title,
        descricao: insight.description,
        severidade: insight.severity,
        cliente: insight.customerName,
        codigosDeReferencia: insight.dataPointCodes,
      })),
    },
    null,
    0,
  );

  return { systemPrompt, userPrompt };
}

function findForbiddenCommercialTerm(text: string): string | null {
  const normalized = text.toLowerCase();
  return FORBIDDEN_COMMERCIAL_TERMS.find((term) => normalized.includes(term)) ?? null;
}

/**
 * Validates a raw LLM-generated daily summary against the exact [payload]
 * that produced its prompt. Same three mandatory checks as
 * `validateGeneratedSummary` (TASK-186) — missing/unknown references,
 * hallucinated numbers — plus a fourth, specific to this feature: since this
 * text is dispatched automatically as a notification with no human review in
 * between (unlike `suggestApproach`'s editable draft), it must never contain
 * discount/price/contractual-promise vocabulary
 * ({@link FORBIDDEN_COMMERCIAL_TERMS}, TASK-187).
 */
export function validateGeneratedDailyRepSummary(
  text: string,
  payload: DailyRepSummaryPayload,
): DailyRepSummaryValidationOutcome {
  const trimmed = text.trim();
  if (trimmed.length === 0) {
    return { ok: false, reason: 'missing_references', detail: 'Resposta vazia.' };
  }

  const forbiddenTerm = findForbiddenCommercialTerm(trimmed);
  if (forbiddenTerm) {
    return {
      ok: false,
      reason: 'forbidden_commercial_term',
      detail: `O texto gerado menciona "${forbiddenTerm}", termo proibido para um resumo diário.`,
    };
  }

  const citedCodes = extractCitedDataPointCodes(trimmed);
  if (citedCodes.length === 0) {
    return {
      ok: false,
      reason: 'missing_references',
      detail: 'Nenhuma citação [refs: ...] encontrada no texto gerado.',
    };
  }

  const knownCodes = new Set(payload.dataPoints.map((point) => point.code));
  const unknownCode = citedCodes.find((code) => !knownCodes.has(code));
  if (unknownCode) {
    return {
      ok: false,
      reason: 'unknown_reference',
      detail: `Código de referência "${unknownCode}" não existe no payload.`,
    };
  }

  const knownNumericValues = payload.dataPoints
    .map((point) => point.numericValue)
    .filter((value): value is number => typeof value === 'number');

  const hallucinatedToken = findHallucinatedNumberToken(trimmed, knownNumericValues);
  if (hallucinatedToken) {
    return {
      ok: false,
      reason: 'hallucinated_number',
      detail: `Número "${hallucinatedToken}" não corresponde a nenhum dado do payload.`,
    };
  }

  return { ok: true, citedDataPointCodes: citedCodes };
}

/** Resolves cited data-point codes back into the display-ready references
 * the UI renders as expandable citations — mirrors
 * `resolveWalletSummaryReferences`/`resolveApproachSuggestionReferences`. */
export function resolveDailyRepSummaryReferences(
  payload: DailyRepSummaryPayload,
  citedDataPointCodes: readonly string[],
): DailyRepSummaryReference[] {
  const byCode = new Map(payload.dataPoints.map((point) => [point.code, point]));
  return citedDataPointCodes
    .map((code) => byCode.get(code))
    .filter((point): point is DailyRepSummaryDataPoint => point != null)
    .map((point) => ({
      code: point.code,
      label: point.label,
      value: point.value,
      unit: point.unit ?? null,
    }));
}
