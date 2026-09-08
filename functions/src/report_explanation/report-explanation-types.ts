/**
 * Shared vocabulary for the report-explanation feature (TASK-189, EPIC-28 —
 * "IA generativa: explicação de relatórios"). Same shape as
 * `../wallet_summary/wallet-summary-types.ts` (TASK-186) and
 * `../approach_suggestion/approach-suggestion-types.ts` (TASK-187): every
 * type here describes data already computed by `runReportAggregation`
 * (TASK-133/TASK-144, `../reports/execute-report-query.ts`) — this module
 * never introduces a new business calculation, only a read-only, LLM-facing
 * projection of numbers that already exist, each tagged with a stable
 * [ReportExplanationDataPoint.code] so the generated text can cite exactly
 * which one backs a claim (`tasks.md`/TASK-189: "todo número citado deve
 * casar com o payload").
 */

/**
 * One citable fact the LLM is allowed to reference in the generated text —
 * the *only* numbers
 * {@link import('./report-explanation-shared').validateGeneratedReportExplanation}
 * ever accepts as legitimate.
 */
export interface ReportExplanationDataPoint {
  code: string;
  label: string;
  /** Human-readable, already-formatted value — never re-formatted by the
   * LLM prompt itself. */
  value: string;
  /** Same value as [value], parsed to a number — this is what
   * {@link import('./report-explanation-shared').validateGeneratedReportExplanation}
   * actually compares every number found in the generated text against.
   * Omitted for the rare data point whose value is not itself a number
   * (there are none today, kept optional for forward-compatibility, mirroring
   * `WalletSummaryDataPoint.numericValue`). */
  numericValue?: number;
  unit?: string;
}

/** One row of the report's own already-aggregated result
 * (`runReportAggregation`'s output), reduced to what the prompt needs — the
 * dimension values that identify this row (joined into one label) plus the
 * codes of every {@link ReportExplanationDataPoint} this row contributed
 * (one per metric, plus a comparison/change-percent pair when the report
 * requested a period comparison). */
export interface ReportExplanationRowHighlight {
  dimensionLabel: string;
  dataPointCodes: string[];
}

/**
 * The complete, structured, already-verified dataset an `explainReport` call
 * assembles server-side — always re-derived from `runReportAggregation`
 * under the caller's own role/tenant scope (never a `ReportQueryResult`
 * trusted from the client, exactly like `exportReportToCsv`, TASK-146) —
 * before ever calling an LLM provider. Every number the LLM is allowed to
 * mention lives in [dataPoints]; every other field here is either narrative
 * context (labels, period) already derived from the same verified data, or
 * resolvable back to a [dataPoints] entry via a row's `dataPointCodes`.
 */
export interface ReportExplanationPayload {
  organizationId: string;
  companyId: string;
  /** `YYYY-MM` — the filter period the report was executed for. */
  periodKey: string;
  /** Human-readable period label, e.g. `"setembro/2026"` — the prompt is
   * required to state this explicitly (`tasks.md`/TASK-189: "declarar o
   * período de referência dos dados, evitando ambiguidade temporal"). */
  periodLabel: string;
  dimensionLabels: string[];
  metricLabels: string[];
  comparisonPeriod: 'none' | 'previousPeriod' | 'previousYear';
  /** Total number of rows the aggregation produced, before this payload
   * capped how many are described in detail — always the real row count,
   * never estimated. */
  totalRowCount: number;
  /** Highest-value rows included in [rows], capped at
   * `REPORT_EXPLANATION_MAX_ROWS`. */
  rows: ReportExplanationRowHighlight[];
  /** `totalRowCount - rows.length` — how many additional rows exist but were
   * not individually described (still true/deterministic, never fabricated),
   * so the generated text can mention "e outras N linhas" instead of
   * implying [rows] is the complete result. */
  omittedRowCount: number;
  dataPoints: ReportExplanationDataPoint[];
}

/** Result of validating an LLM-generated explanation against its own
 * {@link ReportExplanationPayload} — see
 * `report-explanation-shared.ts`'s `validateGeneratedReportExplanation` doc
 * comment for the full rejection rationale of each reason. */
export type ReportExplanationValidationOutcome =
  | { ok: true; citedDataPointCodes: string[] }
  | {
      ok: false;
      reason: 'missing_references' | 'unknown_reference' | 'hallucinated_number';
      detail: string;
    };

export type ReportExplanationStatus = 'ready' | 'error';

/** One resolved reference the UI renders as an expandable citation next to
 * the sentence(s) that cite it — mirrors `WalletSummaryReference`
 * (TASK-186). */
export interface ReportExplanationReference {
  code: string;
  label: string;
  value: string;
  unit: string | null;
}

/** The `organizations/{organizationId}/reportExplanations/{cacheKey}` cache
 * document — never readable by any client directly (`firestore.rules` denies
 * it outright, same as `walletSummaries`/`approachSuggestions`); the only way
 * a client ever sees this data is through `explainReport`'s own response. */
export interface ReportExplanationCacheDoc {
  organizationId: string;
  companyId: string;
  requestedBy: string;
  savedReportId: string | null;
  status: ReportExplanationStatus;
  /** SHA-256 hex digest of the payload that produced (or attempted to
   * produce) this cache entry — a fresh call whose freshly-rebuilt payload
   * hashes differently never reuses this entry, even within the TTL
   * (`tasks.md`/TASK-189: "cache por relatório + versão dos dados"). */
  payloadHash: string;
  explanationText: string | null;
  references: ReportExplanationReference[] | null;
  errorReason: string | null;
  provider: string | null;
  model: string | null;
  generatedAt: unknown;
  expiresAt: unknown;
  lastAttemptAt: unknown;
}
