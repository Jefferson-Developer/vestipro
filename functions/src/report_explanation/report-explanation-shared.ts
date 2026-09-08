import { createHash } from 'node:crypto';

import {
  extractCitedDataPointCodes,
  findHallucinatedNumberToken,
} from '../shared/citation-validation';
import { formatPeriodLabel } from '../wallet_summary/wallet-summary-shared';
import type { ReportFieldConfig } from '../reports/report-catalog';
import type {
  ReportExplanationDataPoint,
  ReportExplanationPayload,
  ReportExplanationReference,
  ReportExplanationRowHighlight,
  ReportExplanationValidationOutcome,
} from './report-explanation-types';

/**
 * Shared, mostly-pure domain logic for `explainReport` (TASK-189, EPIC-28) —
 * payload assembly (from an already-executed `runReportAggregation` result,
 * never a client-supplied one), prompt construction, post-generation
 * validation and the caching primitives the callable itself orchestrates.
 * Same "shared calculation core, kept separate from the onCall wrapper"
 * shape as `../wallet_summary/wallet-summary-shared.ts` (TASK-186) and
 * `../approach_suggestion/approach-suggestion-shared.ts` (TASK-187) — the
 * riskiest logic (the hallucination guard in
 * {@link validateGeneratedReportExplanation}) stays unit-testable without an
 * onCall wrapper or a real LLM provider.
 *
 * Unlike TASK-186/TASK-187, this feature never re-derives its own RBAC rule:
 * a report explanation is only ever built from rows `runReportAggregation`
 * already scoped to the caller's own role/tenant (SALES_REP limited to their
 * own `scopeId`, SALES_MANAGER limited to their own teams, `catalogForRole`
 * hiding unavailable fields) — reusing that exact function, the same way
 * `exportReportToCsv` (TASK-146) already does, is the entire RBAC boundary
 * here; there is no separate "can this user see this saved report" check to
 * duplicate.
 */

/** How long a generated explanation is reused before a fresh call
 * regenerates it — same value/rationale as
 * `WALLET_SUMMARY_CACHE_TTL_MINUTES`: a real data change (new aggregation
 * run) invalidates the cache immediately even inside this window, since a
 * cache hit also requires the freshly-rebuilt payload's hash to match the
 * cached one (see {@link computePayloadHash}). */
export const REPORT_EXPLANATION_CACHE_TTL_MINUTES = 60;

/** Minimum wait, after a failed generation attempt for the exact same
 * (unchanged) payload, before another provider call is attempted — same
 * reasoning/value as `WALLET_SUMMARY_MIN_RETRY_AFTER_ERROR_MINUTES`. */
export const REPORT_EXPLANATION_MIN_RETRY_AFTER_ERROR_MINUTES = 5;

/** Maximum rows (highest first metric value) ever described individually in
 * one payload — keeps the prompt small and the citation surface reviewable.
 * A report with more rows than this still has every one of them summed into
 * the `total_*` data points; only the per-row detail is capped. */
export const REPORT_EXPLANATION_MAX_ROWS = 15;

export function minutesToMs(minutes: number): number {
  return minutes * 60 * 1000;
}

/** Stable cache-document id: [requesterUid] first, since a report's own
 * rows/aggregation are already scoped per-caller by `runReportAggregation`
 * (a SALES_REP and an OWNER running the identical [reportKey] can
 * legitimately see different rows) — caching per requester, never shared
 * across callers, is the only way a cache hit can never leak one caller's
 * scoped data to another. */
export function reportExplanationCacheKey(params: {
  requesterUid: string;
  savedReportId: string | null;
  definitionFingerprint: string;
}): string {
  const reportKey = params.savedReportId ?? params.definitionFingerprint;
  return createHash('sha256').update(`${params.requesterUid}|${reportKey}`).digest('hex');
}

/** Deterministic fingerprint of the *shape* of a report request (never its
 * result) — used as [reportExplanationCacheKey]'s `reportKey` when no
 * `savedReportId` was supplied (an ad-hoc report still being built in the
 * construtor, TASK-144). */
export function computeDefinitionFingerprint(params: {
  dimensions: string[];
  metrics: string[];
  filters: unknown;
  groupBy: string[];
  sortBy: unknown;
  comparisonPeriod: string;
}): string {
  const combined = JSON.stringify({
    dimensions: [...params.dimensions].sort(),
    metrics: [...params.metrics].sort(),
    filters: params.filters ?? null,
    groupBy: [...params.groupBy].sort(),
    sortBy: params.sortBy ?? null,
    comparisonPeriod: params.comparisonPeriod,
  });
  return createHash('sha256').update(combined).digest('hex');
}

function unitFor(valueType: ReportFieldConfig['valueType']): string | undefined {
  if (valueType === 'currency') return 'BRL';
  if (valueType === 'percentage') return 'percent';
  return undefined;
}

function formatMetricValue(valueType: ReportFieldConfig['valueType'], value: number): string {
  if (valueType === 'currency') return value.toFixed(2);
  if (valueType === 'percentage') return value.toFixed(1);
  if (Number.isInteger(value)) return String(value);
  return value.toFixed(2);
}

function labelFor(catalog: readonly ReportFieldConfig[], id: string): string {
  return catalog.find((field) => field.id === id)?.label ?? id;
}

function numberOrNull(value: unknown): number | null {
  return typeof value === 'number' && Number.isFinite(value) ? value : null;
}

/**
 * Assembles the complete, structured payload `explainReport` sends to the
 * LLM prompt — every number comes straight from [rows], which the callable
 * obtained by re-running `runReportAggregation` itself (never a
 * `ReportQueryResult` trusted from the client). This function performs only
 * deterministic, non-discretionary arithmetic of its own (summing already-
 * validated per-row metric values into a `total_*` data point — the same
 * "add these already-verified numbers together" operation `aggregateRows`
 * itself already performs when it groups snapshot rows) — it never estimates,
 * projects or judges anything a business rule would need to own.
 */
export function buildReportExplanationPayload(params: {
  organizationId: string;
  companyId: string;
  rows: Record<string, unknown>[];
  dimensions: string[];
  metrics: string[];
  catalog: readonly ReportFieldConfig[];
  periodKey: string;
  comparisonPeriod: 'none' | 'previousPeriod' | 'previousYear';
}): ReportExplanationPayload {
  const { organizationId, companyId, rows, dimensions, metrics, catalog, periodKey, comparisonPeriod } = params;
  const dataPoints: ReportExplanationDataPoint[] = [];

  // Deterministic ordering: highest value of the first metric first, so the
  // rows most likely to matter to the reader are the ones kept when the
  // report has more rows than `REPORT_EXPLANATION_MAX_ROWS`.
  const primaryMetric = metrics[0];
  const orderedRows = primaryMetric
    ? [...rows].sort((left, right) => (numberOrNull(right[primaryMetric]) ?? 0) - (numberOrNull(left[primaryMetric]) ?? 0))
    : rows;
  const includedRows = orderedRows.slice(0, REPORT_EXPLANATION_MAX_ROWS);

  const rowHighlights: ReportExplanationRowHighlight[] = includedRows.map((row, index) => {
    const dimensionLabel = dimensions.map((id) => String(row[id] ?? '—')).join(' / ');
    const dataPointCodes: string[] = [];
    for (const metricId of metrics) {
      const rawValue = numberOrNull(row[metricId]);
      if (rawValue == null) continue;
      const valueType = catalog.find((field) => field.id === metricId)?.valueType ?? 'number';
      const code = `row_${index}_${metricId}`;
      dataPoints.push({
        code,
        label: `${labelFor(catalog, metricId)} — ${dimensionLabel}`,
        value: formatMetricValue(valueType, rawValue),
        numericValue: rawValue,
        unit: unitFor(valueType),
      });
      dataPointCodes.push(code);

      if (comparisonPeriod !== 'none') {
        const changePercent = numberOrNull(row[`${metricId}ChangePercent`]);
        if (changePercent != null) {
          const changeCode = `${code}_change_percent`;
          dataPoints.push({
            code: changeCode,
            label: `Variação de ${labelFor(catalog, metricId)} — ${dimensionLabel}`,
            value: changePercent.toFixed(1),
            numericValue: changePercent,
            unit: 'percent',
          });
          dataPointCodes.push(changeCode);
        }
      }
    }
    return { dimensionLabel, dataPointCodes };
  });

  const totalDataPointCodesByMetric: string[] = [];
  for (const metricId of metrics) {
    const valueType = catalog.find((field) => field.id === metricId)?.valueType ?? 'number';
    const total = rows.reduce((sum, row) => sum + (numberOrNull(row[metricId]) ?? 0), 0);
    const code = `total_${metricId}`;
    dataPoints.push({
      code,
      label: `Total de ${labelFor(catalog, metricId)}`,
      value: formatMetricValue(valueType, total),
      numericValue: total,
      unit: unitFor(valueType),
    });
    totalDataPointCodesByMetric.push(code);
  }

  return {
    organizationId,
    companyId,
    periodKey,
    periodLabel: formatPeriodLabel(periodKey),
    dimensionLabels: dimensions.map((id) => labelFor(catalog, id)),
    metricLabels: metrics.map((id) => labelFor(catalog, id)),
    comparisonPeriod,
    totalRowCount: rows.length,
    rows: rowHighlights,
    omittedRowCount: Math.max(rows.length - includedRows.length, 0),
    dataPoints,
  };
}

/** Deterministic SHA-256 hex digest of a payload's *content* — same
 * "stable regardless of key order, invalidates on any relevant data change"
 * contract as `../wallet_summary/wallet-summary-shared.ts`'s
 * `computePayloadHash`. */
export function computePayloadHash(payload: ReportExplanationPayload): string {
  const sortedDataPoints = [...payload.dataPoints]
    .map((point) => ({
      code: point.code,
      value: point.value,
      numericValue: point.numericValue ?? null,
      unit: point.unit ?? null,
    }))
    .sort((left, right) => left.code.localeCompare(right.code));
  const combined = JSON.stringify({
    periodKey: payload.periodKey,
    dimensionLabels: [...payload.dimensionLabels].sort(),
    metricLabels: [...payload.metricLabels].sort(),
    comparisonPeriod: payload.comparisonPeriod,
    totalRowCount: payload.totalRowCount,
    omittedRowCount: payload.omittedRowCount,
    dataPoints: sortedDataPoints,
  });
  return createHash('sha256').update(combined).digest('hex');
}

/**
 * Builds the fixed prompt template (`tasks.md`/TASK-189: "Prompt template
 * restrito a descrever tendências, comparações e destaques presentes no
 * payload — proibido calcular percentuais/números que não estejam no
 * payload de entrada"). The system prompt carries every rule; the user
 * prompt carries only the data, serialized as JSON — never a free-form query
 * or client-typed text, so nothing beyond already-verified numbers/labels
 * ever reaches the model.
 */
export function buildReportExplanationPrompt(payload: ReportExplanationPayload): {
  systemPrompt: string;
  userPrompt: string;
} {
  const systemPrompt = [
    'Você narra, em português do Brasil, o conteúdo de UM relatório comercial já calculado, para quem está olhando o gráfico/tabela ao lado.',
    'Regras obrigatórias, sem exceção:',
    '1. Use exclusivamente os números presentes em "dataPoints". Nunca calcule, estime, arredonde de forma diferente ou invente qualquer valor numérico que não exista literalmente em "dataPoints" — os totais e variações já vêm prontos, você apenas os descreve.',
    '2. Toda frase que mencionar um número deve terminar com uma citação no formato "[refs: codigo1, codigo2]", usando exatamente os valores de "code" de "dataPoints".',
    '3. Comece o texto declarando claramente o período de referência dos dados, usando exatamente o texto de "periodo" fornecido, sem alterá-lo — nunca deixe ambíguo a qual período os números se referem.',
    '4. Nunca recomende ou determine uma ação comercial — o texto é apenas descritivo, nunca prescritivo.',
    '5. Se "linhasOmitidas" for maior que zero, mencione que existem outras linhas não detalhadas individualmente, usando esse valor exato.',
    '6. Seja objetivo: no máximo 6 frases, tom profissional e direto.',
  ].join('\n');

  const userPrompt = JSON.stringify(
    {
      periodo: payload.periodLabel,
      dimensoes: payload.dimensionLabels,
      metricas: payload.metricLabels,
      comparacao: payload.comparisonPeriod,
      totalDeLinhas: payload.totalRowCount,
      linhasOmitidas: payload.omittedRowCount,
      linhas: payload.rows.map((row) => ({
        rotulo: row.dimensionLabel,
        codigosDeReferencia: row.dataPointCodes,
      })),
      dataPoints: payload.dataPoints.map((point) => ({
        code: point.code,
        label: point.label,
        value: point.value,
        unit: point.unit ?? null,
      })),
    },
    null,
    0,
  );

  return { systemPrompt, userPrompt };
}

/** Numeric values the generated text is allowed to state *without* a
 * `[refs: ...]` citation — the year/month that make up [payload.periodKey]
 * (the prompt requires stating the period, `tasks.md`/TASK-189: "declarar o
 * período de referência"), plus [payload.totalRowCount]/[payload.omittedRowCount]
 * (the prompt asks the text to mention `linhasOmitidas` verbatim when
 * non-zero). Every one of these already comes from already-verified,
 * deterministic data — never a citable business metric, so requiring a
 * citation for them would only add bureaucracy without a real
 * anti-hallucination benefit; they still must match exactly (no tolerance
 * beyond {@link findHallucinatedNumberToken}'s own), so a fabricated year or
 * row count is rejected exactly like a fabricated revenue figure. */
function contextualNumericValues(payload: ReportExplanationPayload): number[] {
  const [yearStr, monthStr] = payload.periodKey.split('-');
  const values = [payload.totalRowCount, payload.omittedRowCount];
  const year = Number(yearStr);
  const month = Number(monthStr);
  if (Number.isFinite(year)) values.push(year);
  if (Number.isFinite(month)) values.push(month);
  return values;
}

/**
 * Validates a raw LLM-generated explanation against the exact [payload] that
 * produced its prompt — same three independent, all-mandatory checks as
 * `validateGeneratedSummary` (TASK-186): at least one `[refs: ...]` citation,
 * every cited code must exist in the payload, and every numeric token found
 * anywhere in the free text must match (within tolerance) a known numeric
 * value.
 */
export function validateGeneratedReportExplanation(
  text: string,
  payload: ReportExplanationPayload,
): ReportExplanationValidationOutcome {
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

  const knownNumericValues = [
    ...payload.dataPoints
      .map((point) => point.numericValue)
      .filter((value): value is number => typeof value === 'number'),
    ...contextualNumericValues(payload),
  ];

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
export function resolveReportExplanationReferences(
  payload: ReportExplanationPayload,
  citedDataPointCodes: readonly string[],
): ReportExplanationReference[] {
  const byCode = new Map(payload.dataPoints.map((point) => [point.code, point]));
  return citedDataPointCodes
    .map((code) => byCode.get(code))
    .filter((point): point is ReportExplanationDataPoint => point != null)
    .map((point) => ({
      code: point.code,
      label: point.label,
      value: point.value,
      unit: point.unit ?? null,
    }));
}
