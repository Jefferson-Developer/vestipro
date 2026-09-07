import { createHash } from 'node:crypto';

import { HttpsError } from 'firebase-functions/v2/https';
import type { DocumentData, Firestore } from 'firebase-admin/firestore';

import { buildAggregateDocId, formatMonthKey } from '../aggregations/aggregation-shared';
import { addMonthsToMonthKey } from '../demand-forecast/demand-forecast-shared';
import type {
  WalletSummaryDataPoint,
  WalletSummaryInsightHighlight,
  WalletSummaryPayload,
  WalletSummaryReference,
  WalletSummaryTargetRisk,
  WalletSummaryValidationOutcome,
} from './wallet-summary-types';

/**
 * Shared, mostly-pure domain logic for `generateWalletSummary` (TASK-186,
 * EPIC-28) — payload assembly, prompt construction, post-generation
 * validation and the RBAC/caching primitives the callable itself
 * orchestrates. Kept separate from `generate-wallet-summary.ts` so the
 * riskiest logic (the hallucination guard in
 * {@link validateGeneratedSummary}, and multi-tenant scoping in
 * {@link buildWalletSummaryPayload}) is unit-testable without an onCall
 * wrapper or a real LLM provider, same "shared calculation core" shape as
 * `../replenishment/replenishment-calculation-shared.ts` (TASK-184) and
 * `../demand-forecast/demand-forecast-shared.ts` (TASK-185).
 */

/** How long a generated summary is reused before a fresh call regenerates it
 * — `tasks.md`/TASK-186: "Cache do resumo por vendedor/período (TTL curto)
 * para evitar chamadas repetidas ao LLM sem mudança relevante nos dados." A
 * cache hit still requires the freshly-rebuilt payload's hash to match the
 * cached one (see {@link computePayloadHash}), so a real data change (a new
 * insight, an updated month aggregate) invalidates the cache immediately,
 * even inside this window. */
export const WALLET_SUMMARY_CACHE_TTL_MINUTES = 60;

/** Minimum wait, after a failed generation attempt for the exact same
 * (unchanged) payload, before another provider call is attempted — caps cost
 * and request volume toward the LLM provider when it is down or
 * misconfigured (`tasks.md`/TASK-186: "Custo de chamadas ao LLM é
 * controlado por cache e limite de frequência por usuário"). A caller who
 * changes the underlying data (new month, new insight) is never blocked by
 * this — only a retry against the same [payloadHash] is. */
export const WALLET_SUMMARY_MIN_RETRY_AFTER_ERROR_MINUTES = 5;

/** Maximum insights (highest estimated impact first) ever included in one
 * payload — keeps the prompt small and the citation surface reviewable,
 * mirroring `InsightRepository.listPageByRecipient`'s own `limit: 25` used by
 * `LoadRepresentativeDashboardUseCase` (Dart side) for the same "carteira em
 * destaque" scope. */
export const WALLET_SUMMARY_MAX_INSIGHTS = 10;

const MS_PER_MINUTE = 60 * 1000;

const PT_BR_MONTH_NAMES = [
  'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
  'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
] as const;

export function walletSummaryDocId(sellerId: string, periodKey: string): string {
  return `${sellerId}_${periodKey}`;
}

export function walletSummaryRef(
  db: Firestore,
  organizationId: string,
  sellerId: string,
  periodKey: string,
) {
  return db
    .collection('organizations')
    .doc(organizationId)
    .collection('walletSummaries')
    .doc(walletSummaryDocId(sellerId, periodKey));
}

/** `YYYY-MM` -> `"setembro/2026"`. */
export function formatPeriodLabel(periodKey: string): string {
  const [yearStr, monthStr] = periodKey.split('-');
  const monthIndex = Number(monthStr) - 1;
  const monthName = PT_BR_MONTH_NAMES[monthIndex] ?? monthStr;
  return `${monthName}/${yearStr}`;
}

/**
 * Deterministic SHA-256 hex digest of a payload's *content* (every field
 * except [WalletSummaryPayload.sellerName]/labels, which are display-only —
 * a name change alone must never invalidate an otherwise-unchanged cache
 * entry). Two calls that assemble the exact same underlying numbers always
 * hash identically, regardless of object key order, so a cache hit
 * ({@link WALLET_SUMMARY_CACHE_TTL_MINUTES} still open) is only ever reused
 * when nothing relevant actually changed.
 */
export function computePayloadHash(payload: WalletSummaryPayload): string {
  const sortedDataPoints = [...payload.dataPoints]
    .map((point) => ({
      code: point.code,
      value: point.value,
      numericValue: point.numericValue ?? null,
      unit: point.unit ?? null,
    }))
    .sort((left, right) => left.code.localeCompare(right.code));
  const stableInsightIds = [...payload.insights]
    .map((insight) => insight.insightId)
    .sort();
  const combined = JSON.stringify({
    periodKey: payload.periodKey,
    dataPoints: sortedDataPoints,
    insightIds: stableInsightIds,
    hasTargetRisk: payload.targetRisk != null,
  });
  return createHash('sha256').update(combined).digest('hex');
}

/** Same "manager scoped to their own team" RBAC shape already enforced
 * server-side by `../orders/decide-order-approval.ts` (TASK-103) — a wallet
 * summary is at least as sensitive (revenue, target risk, named
 * customers), so it never uses a looser rule. `OWNER`/`ADMIN` may request
 * any seller's wallet in the organization; a seller may always request
 * their own; `SALES_MANAGER` only when the target seller shares at least
 * one of the manager's own teams; every other role (`SALES_REP` requesting
 * someone else's wallet, `SALES_ASSISTANT`, `FINANCE`, `READ_ONLY`) is
 * denied.
 */
export async function assertCanAccessSellerWallet(params: {
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
    const organizationRef = db.collection('organizations').doc(organizationId);
    const [requesterSnapshot, sellerSnapshot] = await Promise.all([
      organizationRef.collection('members').doc(requesterUid).get(),
      organizationRef.collection('members').doc(sellerId).get(),
    ]);
    const requesterTeamIds = normalizeTeamIds(requesterSnapshot.data()?.teamIds);
    const sellerTeamIds = normalizeTeamIds(sellerSnapshot.data()?.teamIds);
    const sharesTeam = sellerTeamIds.some((teamId) => requesterTeamIds.includes(teamId));
    if (sharesTeam) return;
  }

  throw new HttpsError(
    'permission-denied',
    'Você só pode gerar o resumo da sua própria carteira ou da carteira de vendedores da sua equipe.',
  );
}

function normalizeTeamIds(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.filter((entry): entry is string => typeof entry === 'string');
}

/**
 * Assembles the complete, structured payload `generateWalletSummary` sends
 * to the LLM prompt — every number comes straight from already-computed,
 * server-side data (`representativeMonthlyAggregates`, TASK-133; `Insight`,
 * TASK-121), scoped to [organizationId]/[companyId]/[sellerId] by
 * Firestore path alone (never a client-supplied filter the query trusts
 * blindly), so a payload for one organization can structurally never carry a
 * fact from another (`tasks.md`/TASK-186: "O modelo nunca recebe dados de
 * outra organização").
 */
export async function buildWalletSummaryPayload(params: {
  db: Firestore;
  organizationId: string;
  companyId: string;
  sellerId: string;
  sellerName: string;
  now: Date;
}): Promise<WalletSummaryPayload> {
  const { db, organizationId, companyId, sellerId, sellerName, now } = params;
  const periodKey = formatMonthKey(now);
  const previousPeriodKey = addMonthsToMonthKey(periodKey, -1);
  const organizationRef = db.collection('organizations').doc(organizationId);
  const aggregatesRef = organizationRef.collection('representativeMonthlyAggregates');

  const [currentSnapshot, previousSnapshot, ownInsightsSnapshot, targetRiskSnapshot] =
    await Promise.all([
      aggregatesRef.doc(buildAggregateDocId(companyId, sellerId, periodKey)).get(),
      aggregatesRef.doc(buildAggregateDocId(companyId, sellerId, previousPeriodKey)).get(),
      organizationRef
        .collection('insights')
        .where('recipientUserId', '==', sellerId)
        .where('status', '==', 'fresh')
        .limit(50)
        .get(),
      organizationRef
        .collection('insights')
        .where('sellerId', '==', sellerId)
        .where('type', '==', 'sellerBelowTarget')
        .where('status', '==', 'fresh')
        .limit(5)
        .get(),
    ]);

  const dataPoints: WalletSummaryDataPoint[] = [];

  const currentData = currentSnapshot.data();
  const revenueCurrentMonth = numberOrZero(currentData?.revenueNet);
  const orderCountCurrentMonth = numberOrZero(currentData?.orderCount);
  dataPoints.push({
    code: 'revenue_current_month',
    label: `Faturamento líquido de ${formatPeriodLabel(periodKey)}`,
    value: revenueCurrentMonth.toFixed(2),
    numericValue: revenueCurrentMonth,
    unit: 'BRL',
  });
  dataPoints.push({
    code: 'order_count_current_month',
    label: `Pedidos em ${formatPeriodLabel(periodKey)}`,
    value: `${orderCountCurrentMonth}`,
    numericValue: orderCountCurrentMonth,
  });

  let revenuePreviousMonthDataPointCode: string | null = null;
  if (previousSnapshot.exists) {
    const revenuePreviousMonth = numberOrZero(previousSnapshot.data()?.revenueNet);
    dataPoints.push({
      code: 'revenue_previous_month',
      label: `Faturamento líquido de ${formatPeriodLabel(previousPeriodKey)}`,
      value: revenuePreviousMonth.toFixed(2),
      numericValue: revenuePreviousMonth,
      unit: 'BRL',
    });
    revenuePreviousMonthDataPointCode = 'revenue_previous_month';
  }

  const targetRisk = extractTargetRisk(targetRiskSnapshot.docs.map((doc) => doc.data()), dataPoints);

  const insights = ownInsightsSnapshot.docs
    .map((doc) => extractInsightHighlight(doc.id, doc.data(), dataPoints))
    .sort((left, right) => impactScore(right) - impactScore(left))
    .slice(0, WALLET_SUMMARY_MAX_INSIGHTS);

  return {
    organizationId,
    companyId,
    sellerId,
    sellerName,
    periodKey,
    periodLabel: formatPeriodLabel(periodKey),
    revenueCurrentMonthDataPointCode: 'revenue_current_month',
    revenueOrderCountDataPointCode: 'order_count_current_month',
    revenuePreviousMonthDataPointCode,
    targetRisk,
    insights,
    dataPoints,
  };
}

function extractTargetRisk(
  candidates: DocumentData[],
  dataPoints: WalletSummaryDataPoint[],
): WalletSummaryTargetRisk | null {
  if (candidates.length === 0) return null;
  // Highest estimated impact first — same tie-break `evaluateInsights`
  // already applies, kept local here since this is a single-document read,
  // not a full rules evaluation.
  const sorted = [...candidates].sort(
    (left, right) =>
      numberOrZero(right.estimatedImpact?.amount) -
      numberOrZero(left.estimatedImpact?.amount),
  );
  const insight = sorted[0];
  const evidence = Array.isArray(insight.evidence) ? insight.evidence : [];
  const targetValue = findEvidenceNumericValue(evidence, 'target_value') ?? 0;
  const realizedValue = findEvidenceNumericValue(evidence, 'realized_value') ?? 0;
  const projectedAchievementPercentage =
    findEvidenceNumericValue(evidence, 'projected_achievement_percentage') ?? 0;

  const insightId = String(insight.id ?? `${insight.sellerId}_target_risk`);
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
    title: String(insight.title ?? ''),
    description: String(insight.description ?? ''),
    targetValue,
    realizedValue,
    projectedAchievementPercentage,
    dataPointCodes: [targetValueCode, realizedValueCode, projectedCode],
  };
}

function extractInsightHighlight(
  insightId: string,
  data: DocumentData,
  dataPoints: WalletSummaryDataPoint[],
): WalletSummaryInsightHighlight {
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
    customerName: typeof data.customerName === 'string' ? data.customerName : null,
    impactAmount,
    impactPercentage,
    dataPointCodes,
  };
}

function findEvidenceNumericValue(
  evidence: DocumentData[],
  code: string,
): number | null {
  const match = evidence.find((item) => item?.code === code);
  return typeof match?.numericValue === 'number' ? match.numericValue : null;
}

function impactScore(insight: WalletSummaryInsightHighlight): number {
  return (insight.impactAmount ?? 0) + (insight.impactPercentage ?? 0) * 1000;
}

function numberOrZero(value: unknown): number {
  return typeof value === 'number' && Number.isFinite(value) ? value : 0;
}

/**
 * Builds the fixed prompt template (`tasks.md`/TASK-186: "prompt template
 * fixo que restringe a resposta a resumir os dados fornecidos, proibindo
 * introduzir números não presentes no payload"). The system prompt carries
 * every rule; the user prompt carries only the data, serialized as JSON —
 * never free text the seller/manager typed, so nothing beyond
 * already-verified numbers/labels ever reaches the model.
 */
export function buildWalletSummaryPrompt(payload: WalletSummaryPayload): {
  systemPrompt: string;
  userPrompt: string;
} {
  const systemPrompt = [
    'Você resume, em português do Brasil, o desempenho comercial de UM vendedor para o próprio vendedor ou seu gestor.',
    'Regras obrigatórias, sem exceção:',
    '1. Use exclusivamente os números presentes em "dataPoints". Nunca calcule, estime, arredonde de forma diferente ou invente qualquer valor numérico que não exista literalmente em "dataPoints".',
    '2. Toda frase que mencionar um número deve terminar com uma citação no formato "[refs: codigo1, codigo2]", usando exatamente os valores de "code" de "dataPoints" ou dos elementos de "insights"/"targetRisk" que embasaram a frase.',
    '3. Nunca recomende ou determine uma ação comercial (desconto, contato, criação de pedido) — o resumo é apenas informativo.',
    '4. Se não houver dados suficientes para um tópico (ex.: sem mês anterior, sem risco de meta), simplesmente omita esse tópico, nunca invente um valor para preenchê-lo.',
    '5. Seja objetivo: no máximo 6 frases, tom profissional e direto.',
  ].join('\n');

  const userPrompt = JSON.stringify(
    {
      vendedor: payload.sellerName,
      periodo: payload.periodLabel,
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

const REFERENCE_BLOCK_PATTERN = /\[refs:\s*([^\]]+)\]/gi;
// Matches any digit run that may contain "." and/or "," as internal
// separators (pt-BR grouped thousands + comma-decimal, e.g. "12.500,50";
// plain comma-decimal with no thousands grouping, e.g. "12500,50"; or plain
// dot-decimal, e.g. "12500.50"), optionally preceded by "R$" and/or followed
// by "%". The captured group always starts and ends on an actual digit —
// `(?:[\d.,]*\d)?` forces the engine to backtrack off any trailing "."/","
// picked up from surrounding punctuation (e.g. a sentence-ending comma right
// before a citation block), so a token like "9800,00," from
// "...9800,00, ..." is never captured with its trailing separator glued on.
// Deliberately does not try to match ordinals/dates — those never appear in
// this feature's numeric vocabulary (revenue, order counts, percentages).
const NUMBER_TOKEN_PATTERN = /(?:R\$\s*)?(\d(?:[\d.,]*\d)?)\s*%?/g;

/**
 * Extracts every citation block (`[refs: a, b]`) from [text], returning the
 * distinct set of codes cited.
 */
export function extractCitedDataPointCodes(text: string): string[] {
  const codes = new Set<string>();
  for (const match of text.matchAll(REFERENCE_BLOCK_PATTERN)) {
    match[1]
      .split(',')
      .map((code) => code.trim())
      .filter((code) => code.length > 0)
      .forEach((code) => codes.add(code));
  }
  return [...codes];
}

/** Parses a pt-BR or plain-decimal numeric token into a `number`, tolerating
 * both `"1.234,56"` (thousands `.`, decimal `,`) and `"1234.56"` (plain
 * decimal `.`, no thousands separator) — the two shapes this feature's own
 * {@link WalletSummaryDataPoint.value} formatting
 * (`Number.prototype.toFixed`) and a Portuguese-writing LLM are each likely
 * to produce. */
export function parseFlexibleNumber(token: string): number | null {
  const trimmed = token.trim();
  if (trimmed.length === 0) return null;
  const hasComma = trimmed.includes(',');
  const hasDot = trimmed.includes('.');
  let normalized = trimmed;
  if (hasComma && hasDot) {
    // pt-BR thousands+decimal: strip '.', decimal is ','.
    normalized = trimmed.replace(/\./g, '').replace(',', '.');
  } else if (hasComma) {
    normalized = trimmed.replace(',', '.');
  }
  const value = Number(normalized);
  return Number.isFinite(value) ? value : null;
}

const NUMBER_MATCH_TOLERANCE = 0.01;

/**
 * Validates a raw LLM-generated summary against the exact
 * [payload] that produced its prompt (`tasks.md`/TASK-186: "Validação
 * pós-geração: a Function verifica se todo valor numérico citado no texto
 * existe no payload de entrada; resposta com número fora do payload é
 * rejeitada"). Three independent, all-mandatory checks:
 *
 * 1. At least one `[refs: ...]` citation block must be present — a summary
 *    with zero citations has zero rastreabilidade, rejected outright
 *    (`missing_references`).
 * 2. Every code named inside a citation block must exist in
 *    [payload.dataPoints] (or be a "known" alias — see below) —
 *    `unknown_reference` otherwise, since a fabricated citation code is just
 *    as untrustworthy as a fabricated number.
 * 3. Every numeric token found anywhere in the free text (not just inside a
 *    citation) must match, within {@link NUMBER_MATCH_TOLERANCE}, at least
 *    one [WalletSummaryDataPoint.numericValue] in the payload —
 *    `hallucinated_number` otherwise. This is the core anti-hallucination
 *    guard: prompt-engineering (rule 1 in
 *    {@link buildWalletSummaryPrompt}) is never trusted alone.
 */
export function validateGeneratedSummary(
  text: string,
  payload: WalletSummaryPayload,
): WalletSummaryValidationOutcome {
  const trimmed = text.trim();
  if (trimmed.length === 0) {
    return { ok: false, reason: 'missing_references', detail: 'Resposta vazia.' };
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

  const textWithoutCitations = trimmed.replace(REFERENCE_BLOCK_PATTERN, ' ');
  for (const match of textWithoutCitations.matchAll(NUMBER_TOKEN_PATTERN)) {
    const parsed = parseFlexibleNumber(match[1]);
    if (parsed == null) continue;
    const matchesKnownValue = knownNumericValues.some(
      (known) => Math.abs(known - parsed) <= NUMBER_MATCH_TOLERANCE,
    );
    if (!matchesKnownValue) {
      return {
        ok: false,
        reason: 'hallucinated_number',
        detail: `Número "${match[0].trim()}" não corresponde a nenhum dado do payload.`,
      };
    }
  }

  return { ok: true, citedDataPointCodes: citedCodes };
}

/** Resolves cited data-point codes back into the display-ready references
 * the UI renders as expandable citations (`tasks.md`/TASK-186: "exibida na
 * UI"). Silently drops a code no longer resolvable (should never happen —
 * {@link validateGeneratedSummary} already rejects an unknown one — kept
 * defensive rather than throwing, since this runs after generation already
 * succeeded). */
export function resolveWalletSummaryReferences(
  payload: WalletSummaryPayload,
  citedDataPointCodes: readonly string[],
): WalletSummaryReference[] {
  const byCode = new Map(payload.dataPoints.map((point) => [point.code, point]));
  return citedDataPointCodes
    .map((code) => byCode.get(code))
    .filter((point): point is WalletSummaryDataPoint => point != null)
    .map((point) => ({
      code: point.code,
      label: point.label,
      value: point.value,
      unit: point.unit ?? null,
    }));
}

export function minutesToMs(minutes: number): number {
  return minutes * MS_PER_MINUTE;
}
