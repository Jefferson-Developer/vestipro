import { createHash } from 'node:crypto';

import { HttpsError } from 'firebase-functions/v2/https';
import type { DocumentData, Firestore } from 'firebase-admin/firestore';

import {
  extractCitedDataPointCodes,
  findHallucinatedNumberToken,
} from '../shared/citation-validation';
import { membersShareTeam } from '../shared/team-membership';
import type {
  ApproachSuggestionActivityHighlight,
  ApproachSuggestionDataPoint,
  ApproachSuggestionInsightHighlight,
  ApproachSuggestionOrderHighlight,
  ApproachSuggestionPayload,
  ApproachSuggestionReference,
  ApproachSuggestionValidationOutcome,
} from './approach-suggestion-types';

/**
 * Shared, mostly-pure domain logic for `suggestApproach` (TASK-187, EPIC-28)
 * — payload assembly, prompt construction, post-generation validation and
 * the RBAC/caching primitives the callable itself orchestrates. Same
 * "shared calculation core, kept separate from the onCall wrapper" shape as
 * `../wallet_summary/wallet-summary-shared.ts` (TASK-186),
 * `../replenishment/replenishment-calculation-shared.ts` (TASK-184) and
 * `../demand-forecast/demand-forecast-shared.ts` (TASK-185) — the riskiest
 * logic (the hallucination/forbidden-term guard in
 * {@link validateGeneratedApproachSuggestion}, and multi-tenant scoping in
 * {@link buildApproachSuggestionPayload}) stays unit-testable without an
 * onCall wrapper or a real LLM provider.
 */

/** How long a generated suggestion is reused before a fresh call regenerates
 * it — shorter than `WALLET_SUMMARY_CACHE_TTL_MINUTES` (60) because an
 * abordagem comercial is tied to the seller's *next* contact attempt, not a
 * monthly artifact — still hash-gated (see {@link computePayloadHash}), so a
 * real data change (new order, new activity, new insight) invalidates the
 * cache immediately even inside this window. */
export const APPROACH_SUGGESTION_CACHE_TTL_MINUTES = 15;

/** Minimum wait, after a failed generation attempt for the exact same
 * (unchanged) payload, before another provider call is attempted — same
 * reasoning/value as `WALLET_SUMMARY_MIN_RETRY_AFTER_ERROR_MINUTES`. */
export const APPROACH_SUGGESTION_MIN_RETRY_AFTER_ERROR_MINUTES = 5;

/** Maximum recent orders/activities/insights ever included in one payload —
 * keeps the prompt small and the citation surface reviewable. */
export const APPROACH_SUGGESTION_MAX_ORDERS = 5;
export const APPROACH_SUGGESTION_MAX_ACTIVITIES = 5;
export const APPROACH_SUGGESTION_MAX_INSIGHTS = 8;

/** Never send a seller's free-text CRM note to the LLM provider in full —
 * truncated so a very long note cannot dominate the prompt. */
const ACTIVITY_DESCRIPTION_EXCERPT_MAX_LENGTH = 240;

const MS_PER_MINUTE = 60 * 1000;

export function minutesToMs(minutes: number): number {
  return minutes * MS_PER_MINUTE;
}

export function approachSuggestionDocId(customerId: string): string {
  return customerId;
}

export function approachSuggestionRef(
  db: Firestore,
  organizationId: string,
  customerId: string,
) {
  return db
    .collection('organizations')
    .doc(organizationId)
    .collection('approachSuggestions')
    .doc(approachSuggestionDocId(customerId));
}

const ORDER_STATUS_LABELS: Record<string, string> = {
  draft: 'Rascunho',
  pending_sync: 'Pendente de sincronização',
  submitted: 'Enviado',
  under_review: 'Em análise',
  approved: 'Aprovado',
  rejected: 'Rejeitado',
  processing: 'Em processamento',
  invoiced: 'Faturado',
  partially_invoiced: 'Parcialmente faturado',
  shipped: 'Expedido',
  delivered: 'Entregue',
  cancelled: 'Cancelado',
};

function orderStatusLabel(status: string): string {
  return ORDER_STATUS_LABELS[status] ?? status;
}

const ACTIVITY_TYPE_LABELS: Record<string, string> = {
  phone_call: 'Ligação',
  visit: 'Visita',
  meeting: 'Reunião',
  message: 'Mensagem',
  note: 'Nota',
};

function activityTypeLabel(type: string): string {
  return ACTIVITY_TYPE_LABELS[type] ?? type;
}

/** Same "manager scoped to their own team" RBAC shape already enforced
 * server-side by `../orders/decide-order-approval.ts` (TASK-103) and reused
 * by `../wallet_summary/wallet-summary-shared.ts`'s
 * `assertCanAccessSellerWallet` (TASK-186) — an approach suggestion is at
 * least as sensitive (purchase history, CRM notes, named customer), so it
 * never uses a looser rule. `OWNER`/`ADMIN` may request a suggestion for any
 * customer in the organization; the customer's own `responsibleSellerId`
 * may always request it; `SALES_MANAGER` only when that responsible seller
 * shares at least one of the manager's own teams; every other role (a
 * `SALES_REP` who is not the responsible seller, `SALES_ASSISTANT`,
 * `FINANCE`, `READ_ONLY`, `CUSTOMER_PORTAL`) is denied. A customer with no
 * `responsibleSellerId` at all (not yet assigned to a portfolio) is only
 * reachable by `OWNER`/`ADMIN`.
 */
export async function assertCanAccessCustomer(params: {
  db: Firestore;
  organizationId: string;
  requesterUid: string;
  requesterRoleName: string;
  customerId: string;
}): Promise<{ responsibleSellerId: string | null }> {
  const { db, organizationId, requesterUid, requesterRoleName, customerId } = params;
  const customerSnapshot = await db
    .collection('organizations')
    .doc(organizationId)
    .collection('customers')
    .doc(customerId)
    .get();
  if (!customerSnapshot.exists) {
    throw new HttpsError('not-found', 'Cliente não encontrado nesta organização.');
  }
  const responsibleSellerId =
    (customerSnapshot.data()?.responsibleSellerId as string | undefined)?.trim() || null;

  if (requesterRoleName === 'OWNER' || requesterRoleName === 'ADMIN') {
    return { responsibleSellerId };
  }
  if (responsibleSellerId && requesterUid === responsibleSellerId) {
    return { responsibleSellerId };
  }
  if (responsibleSellerId && requesterRoleName === 'SALES_MANAGER') {
    const sharesTeam = await membersShareTeam({
      db,
      organizationId,
      uidA: requesterUid,
      uidB: responsibleSellerId,
    });
    if (sharesTeam) {
      return { responsibleSellerId };
    }
  }

  throw new HttpsError(
    'permission-denied',
    'Você só pode gerar uma sugestão de abordagem para um cliente da sua carteira ou da carteira de vendedores da sua equipe.',
  );
}

/**
 * Assembles the complete, structured payload `suggestApproach` sends to the
 * LLM prompt — every fact comes straight from already-persisted, real,
 * server-side data (`orders`, `crmActivities`, `insights` — TASK-121),
 * scoped to [organizationId]/[customerId] by Firestore path/query alone
 * (never a client-supplied filter the query trusts blindly), so a payload
 * for one organization/customer can structurally never carry a fact from
 * another (`tasks.md`/TASK-187: "Payload restrito ao cliente e à
 * organização do vendedor autenticado; nunca comparação cruzada com dados
 * de outro tenant").
 */
export async function buildApproachSuggestionPayload(params: {
  db: Firestore;
  organizationId: string;
  companyId: string;
  customerId: string;
  customerName: string;
  customerSegment: string | null;
  customerPotential: string | null;
}): Promise<ApproachSuggestionPayload> {
  const {
    db,
    organizationId,
    companyId,
    customerId,
    customerName,
    customerSegment,
    customerPotential,
  } = params;
  const organizationRef = db.collection('organizations').doc(organizationId);

  const [ordersSnapshot, activitiesSnapshot, insightsSnapshot] = await Promise.all([
    organizationRef
      .collection('orders')
      .where('companyId', '==', companyId)
      .where('deletedAt', '==', null)
      .where('customerId', '==', customerId)
      .orderBy('createdAt', 'desc')
      .limit(APPROACH_SUGGESTION_MAX_ORDERS)
      .get(),
    organizationRef
      .collection('crmActivities')
      .where('customerId', '==', customerId)
      .orderBy('occurredAt', 'desc')
      .limit(APPROACH_SUGGESTION_MAX_ACTIVITIES)
      .get(),
    organizationRef
      .collection('insights')
      .where('customerId', '==', customerId)
      .where('status', '==', 'fresh')
      .limit(50)
      .get(),
  ]);

  const dataPoints: ApproachSuggestionDataPoint[] = [];

  const recentOrders: ApproachSuggestionOrderHighlight[] = ordersSnapshot.docs.map((doc) =>
    extractOrderHighlight(doc.id, doc.data(), dataPoints),
  );

  const recentActivities: ApproachSuggestionActivityHighlight[] = activitiesSnapshot.docs
    .map((doc) => extractActivityHighlight(doc.data()))
    .filter((activity): activity is ApproachSuggestionActivityHighlight => activity != null);

  const insights = insightsSnapshot.docs
    .map((doc) => extractInsightHighlight(doc.id, doc.data(), dataPoints))
    .sort((left, right) => impactScore(right) - impactScore(left))
    .slice(0, APPROACH_SUGGESTION_MAX_INSIGHTS);

  return {
    organizationId,
    companyId,
    customerId,
    customerName,
    customerSegment,
    customerPotential,
    recentOrders,
    recentActivities,
    insights,
    // See `ApproachSuggestionPayload.recentOutcomeReason`'s own doc
    // comment: Opportunities/win-loss reasons have no Firestore-backed
    // source today, so this is always null — never fabricated, never read
    // from a client-supplied field.
    recentOutcomeReason: null,
    dataPoints,
  };
}

function extractOrderHighlight(
  orderId: string,
  data: DocumentData,
  dataPoints: ApproachSuggestionDataPoint[],
): ApproachSuggestionOrderHighlight {
  const items = Array.isArray(data.items) ? data.items : [];
  const itemCount = items.length;
  const totalAmount = computeOrderTotal(data);
  const totalAmountDataPointCode = `order_${orderId}_total_amount`;
  dataPoints.push({
    code: totalAmountDataPointCode,
    label: `Valor do pedido ${String(data.orderNumber ?? orderId)}`,
    value: totalAmount.toFixed(2),
    numericValue: totalAmount,
    unit: 'BRL',
  });
  const submittedAt = dateFromFirestore(data.createdAt) ?? new Date(0);
  return {
    orderNumber: String(data.orderNumber ?? orderId),
    submittedAt: submittedAt.toISOString(),
    statusLabel: orderStatusLabel(String(data.status ?? '')),
    itemCount,
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

function extractActivityHighlight(
  data: DocumentData,
): ApproachSuggestionActivityHighlight | null {
  const occurredAt = dateFromFirestore(data.occurredAt);
  if (!occurredAt) return null;
  const description = typeof data.description === 'string' ? data.description : '';
  return {
    typeLabel: activityTypeLabel(String(data.type ?? '')),
    occurredAt: occurredAt.toISOString(),
    descriptionExcerpt: truncate(description, ACTIVITY_DESCRIPTION_EXCERPT_MAX_LENGTH),
  };
}

function truncate(value: string, maxLength: number): string {
  const trimmed = value.trim();
  if (trimmed.length <= maxLength) return trimmed;
  return `${trimmed.slice(0, maxLength).trim()}…`;
}

function extractInsightHighlight(
  insightId: string,
  data: DocumentData,
  dataPoints: ApproachSuggestionDataPoint[],
): ApproachSuggestionInsightHighlight {
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
  const impactPercentage =
    typeof data.estimatedImpact?.percentage === 'number'
      ? data.estimatedImpact.percentage
      : null;
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

  return {
    insightId,
    type: String(data.type ?? 'unknown'),
    title: String(data.title ?? ''),
    description: String(data.description ?? ''),
    severity: String(data.severity ?? 'low'),
    impactAmount,
    impactPercentage,
    dataPointCodes,
  };
}

function impactScore(insight: ApproachSuggestionInsightHighlight): number {
  return (insight.impactAmount ?? 0) + (insight.impactPercentage ?? 0) * 1000;
}

function numberOrZero(value: unknown): number {
  return typeof value === 'number' && Number.isFinite(value) ? value : 0;
}

function dateFromFirestore(value: unknown): Date | null {
  if (value && typeof (value as { toDate?: () => Date }).toDate === 'function') {
    return (value as { toDate: () => Date }).toDate();
  }
  if (value instanceof Date) return value;
  if (typeof value === 'string') {
    const parsed = new Date(value);
    return Number.isNaN(parsed.getTime()) ? null : parsed;
  }
  return null;
}

/**
 * Deterministic SHA-256 hex digest of a payload's *content* — same
 * "stable regardless of key order, invalidates on any relevant data change"
 * contract as `../wallet_summary/wallet-summary-shared.ts`'s
 * `computePayloadHash`. Display-only fields ([ApproachSuggestionPayload.customerName]
 * label, etc.) are excluded so a name change alone never invalidates an
 * otherwise-unchanged cache entry.
 */
export function computePayloadHash(payload: ApproachSuggestionPayload): string {
  const sortedDataPoints = [...payload.dataPoints]
    .map((point) => ({
      code: point.code,
      value: point.value,
      numericValue: point.numericValue ?? null,
      unit: point.unit ?? null,
    }))
    .sort((left, right) => left.code.localeCompare(right.code));
  const orderNumbers = payload.recentOrders.map((order) => order.orderNumber).sort();
  const activitySignatures = payload.recentActivities
    .map((activity) => `${activity.occurredAt}:${activity.typeLabel}`)
    .sort();
  const insightIds = payload.insights.map((insight) => insight.insightId).sort();
  const combined = JSON.stringify({
    dataPoints: sortedDataPoints,
    orderNumbers,
    activitySignatures,
    insightIds,
    hasOutcomeReason: payload.recentOutcomeReason != null,
  });
  return createHash('sha256').update(combined).digest('hex');
}

/**
 * Builds the fixed prompt template (`tasks.md`/TASK-187: "Prompt template
 * restringe o modelo a gerar um roteiro de abordagem citando apenas fatos
 * presentes no payload — proibido introduzir promessas, descontos ou dados
 * não fornecidos"). The system prompt carries every rule; the user prompt
 * carries only the data, serialized as JSON — never free text the seller
 * typed, so nothing beyond already-verified facts ever reaches the model.
 */
export function buildApproachSuggestionPrompt(payload: ApproachSuggestionPayload): {
  systemPrompt: string;
  userPrompt: string;
} {
  const systemPrompt = [
    'Você redige, em português do Brasil, um roteiro curto de abordagem comercial que um vendedor de moda B2B usará como ponto de partida — nunca o texto final — antes de contatar UM cliente específico.',
    'Regras obrigatórias, sem exceção:',
    '1. Use exclusivamente os fatos presentes em "dataPoints", "pedidosRecentes", "atividadesRecentes" e "insightsAtivos". Nunca calcule, estime ou invente qualquer valor numérico, nome de produto ou fato que não exista literalmente nesses campos.',
    '2. Toda frase que mencionar um número deve terminar com uma citação no formato "[refs: codigo1, codigo2]", usando exatamente os valores de "code" de "dataPoints".',
    '3. Nunca mencione, sugira ou de a entender qualquer desconto, condição de pagamento, preço, promoção, cortesia, brinde ou parcelamento especial — isso é responsabilidade exclusiva do motor de precificação e das políticas comerciais, nunca deste roteiro.',
    '4. Nunca use linguagem que soe como compromisso contratual da empresa (ex.: "garantimos", "prometemos", "compromisso da empresa") nem falsa urgência.',
    '5. O texto é sempre um rascunho para o vendedor revisar e editar — nunca escreva como se fosse uma mensagem já pronta para envio automático, nem inclua saudação/assinatura.',
    '6. Se não houver dados suficientes sobre um tópico (ex.: sem pedidos recentes, sem insights), simplesmente omita esse tópico, nunca invente um valor para preenchê-lo.',
    '7. Seja objetivo: no máximo 5 frases, tom profissional e consultivo.',
  ].join('\n');

  const userPrompt = JSON.stringify(
    {
      cliente: payload.customerName,
      segmento: payload.customerSegment,
      potencial: payload.customerPotential,
      dataPoints: payload.dataPoints.map((point) => ({
        code: point.code,
        label: point.label,
        value: point.value,
        unit: point.unit ?? null,
      })),
      pedidosRecentes: payload.recentOrders.map((order) => ({
        numero: order.orderNumber,
        data: order.submittedAt,
        status: order.statusLabel,
        quantidadeItens: order.itemCount,
        codigoValorTotal: order.totalAmountDataPointCode,
      })),
      atividadesRecentes: payload.recentActivities.map((activity) => ({
        tipo: activity.typeLabel,
        data: activity.occurredAt,
        descricao: activity.descriptionExcerpt,
      })),
      insightsAtivos: payload.insights.map((insight) => ({
        tipo: insight.type,
        titulo: insight.title,
        descricao: insight.description,
        severidade: insight.severity,
        codigosDeReferencia: insight.dataPointCodes,
      })),
      motivoDePerdaOuGanhoRecente: payload.recentOutcomeReason,
    },
    null,
    0,
  );

  return { systemPrompt, userPrompt };
}

/** Vocabulary that must never appear in a generated approach suggestion,
 * regardless of context — `tasks.md`/TASK-187: "Nunca sugerir desconto,
 * condição comercial ou preço" and "O texto gerado deve evitar linguagem que
 * pareça compromisso contratual da empresa". Prompt-engineering (rule 3/4 in
 * {@link buildApproachSuggestionPrompt}) is never trusted alone — this is
 * the actual enforcement, same "validate the output, not just the prompt"
 * philosophy as {@link findHallucinatedNumberToken}. Matching is
 * case-insensitive and substring-based (not word-boundary-aware) so a
 * plural/inflected form (e.g. "descontos") is still caught. */
export const FORBIDDEN_COMMERCIAL_TERMS: readonly string[] = [
  'desconto',
  'cortesia',
  'brinde',
  'promoç',
  'promo especial',
  'parcelamento especial',
  'condição especial',
  'condições especiais',
  'isento',
  'gratuito',
  'grátis',
  'sem custo',
  'garantimos',
  'prometemos',
  'compromisso da empresa',
];

function findForbiddenCommercialTerm(text: string): string | null {
  const normalized = text.toLowerCase();
  return FORBIDDEN_COMMERCIAL_TERMS.find((term) => normalized.includes(term)) ?? null;
}

/**
 * Validates a raw LLM-generated approach suggestion against the exact
 * [payload] that produced its prompt. Four independent, all-mandatory
 * checks (the first three mirror
 * `../wallet_summary/wallet-summary-shared.ts`'s `validateGeneratedSummary`
 * exactly; the fourth is specific to this feature's own hard business
 * rule):
 *
 * 1. At least one `[refs: ...]` citation block must be present —
 *    `missing_references` otherwise.
 * 2. Every code named inside a citation block must exist in
 *    [payload.dataPoints] — `unknown_reference` otherwise.
 * 3. Every numeric token found anywhere in the free text must match, within
 *    tolerance, at least one known numeric value in the payload —
 *    `hallucinated_number` otherwise.
 * 4. The text must never contain a term from
 *    {@link FORBIDDEN_COMMERCIAL_TERMS} (discount/price/contractual-promise
 *    vocabulary) — `forbidden_commercial_term` otherwise, regardless of
 *    whether that term happens to carry a citation. This check runs even
 *    when the provider never mentions a number at all, since a forbidden
 *    term needs no number to be a policy violation.
 */
export function validateGeneratedApproachSuggestion(
  text: string,
  payload: ApproachSuggestionPayload,
): ApproachSuggestionValidationOutcome {
  const trimmed = text.trim();
  if (trimmed.length === 0) {
    return { ok: false, reason: 'missing_references', detail: 'Resposta vazia.' };
  }

  const forbiddenTerm = findForbiddenCommercialTerm(trimmed);
  if (forbiddenTerm) {
    return {
      ok: false,
      reason: 'forbidden_commercial_term',
      detail: `O texto gerado menciona "${forbiddenTerm}", termo proibido para uma sugestão de abordagem.`,
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
 * `resolveWalletSummaryReferences` (TASK-186). */
export function resolveApproachSuggestionReferences(
  payload: ApproachSuggestionPayload,
  citedDataPointCodes: readonly string[],
): ApproachSuggestionReference[] {
  const byCode = new Map(payload.dataPoints.map((point) => [point.code, point]));
  return citedDataPointCodes
    .map((code) => byCode.get(code))
    .filter((point): point is ApproachSuggestionDataPoint => point != null)
    .map((point) => ({
      code: point.code,
      label: point.label,
      value: point.value,
      unit: point.unit ?? null,
    }));
}
