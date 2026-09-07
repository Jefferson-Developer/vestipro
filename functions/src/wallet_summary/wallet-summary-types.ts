/**
 * Shared vocabulary for the wallet summary feature (TASK-186, EPIC-28 —
 * "IA generativa: resumo de carteira"). Every type here describes data that
 * is already computed elsewhere in this codebase (`representativeMonthlyAggregates`,
 * TASK-133; `Insight`, TASK-121) — this module never introduces a new
 * calculation of its own, only a read-only, LLM-facing projection of numbers
 * that already exist, each tagged with a stable [WalletSummaryDataPoint.code]
 * so the generated text can cite exactly which one backs a claim
 * (`tasks.md`/TASK-186: "cada frase do resumo gerado referencia o dado de
 * origem").
 */

/**
 * One citable fact the LLM is allowed to reference in the generated text —
 * the *only* numbers {@link import('./wallet-summary-shared').validateGeneratedSummary}
 * ever accepts as legitimate. [code] is stable and unique within one
 * {@link WalletSummaryPayload} (never reused for two different facts), so a
 * `[refs: code]` citation in the generated text always resolves to exactly
 * one entry.
 */
export interface WalletSummaryDataPoint {
  code: string;
  label: string;
  /** Human-readable, already-formatted value (e.g. `"12500.00"`, `"3"`,
   * `"-8.5"`) — never re-formatted by the LLM prompt itself. */
  value: string;
  /** Same value as [value], parsed to a number — this is what
   * {@link import('./wallet-summary-shared').validateGeneratedSummary}
   * actually compares every number found in the generated text against.
   * Omitted only for the rare data point whose value is not itself a
   * number (there are none today, but the field stays optional for
   * forward-compatibility, mirroring `InsightEvidence.numericValue` in
   * `functions/src/insights/insight-engine.ts`). */
  numericValue?: number;
  unit?: string;
}

/** One of the seller's own active insights (TASK-121), reduced to what the
 * wallet summary prompt needs — never the full `Insight` shape, so a field
 * this feature does not use (e.g. `quickAction`) can never accidentally leak
 * into the prompt sent to a third-party LLM provider. */
export interface WalletSummaryInsightHighlight {
  insightId: string;
  type: string;
  title: string;
  description: string;
  severity: string;
  customerName: string | null;
  impactAmount: number | null;
  impactPercentage: number | null;
  /** Codes of the {@link WalletSummaryDataPoint}s this insight contributed
   * (its own numbers), for the prompt to point the LLM at when narrating
   * this specific insight. */
  dataPointCodes: string[];
}

/** Seller-below-target risk context (from the manager-facing
 * `sellerBelowTarget` insight, TASK-131) — present only when that insight is
 * currently active for this seller; `null` otherwise (never fabricated when
 * absent, e.g. because the seller is on pace or has no target registered). */
export interface WalletSummaryTargetRisk {
  insightId: string;
  title: string;
  description: string;
  targetValue: number;
  realizedValue: number;
  projectedAchievementPercentage: number;
  dataPointCodes: string[];
}

/**
 * The complete, structured, already-verified dataset a `generateWalletSummary`
 * call assembles server-side before ever calling an LLM provider —
 * `tasks.md`/TASK-186: "a Function monta um payload estruturado (JSON)...
 * nunca dados brutos não verificados nem texto livre". Every number the LLM
 * is allowed to mention lives in [dataPoints]; every other field here is
 * either narrative context (labels/titles) already derived from the same
 * verified data, or resolvable back to a [dataPoints] entry via its
 * `dataPointCodes`.
 */
export interface WalletSummaryPayload {
  organizationId: string;
  companyId: string;
  sellerId: string;
  sellerName: string;
  /** `YYYY-MM`. */
  periodKey: string;
  /** Human-readable period label, e.g. `"setembro/2026"`. */
  periodLabel: string;
  revenueCurrentMonthDataPointCode: string;
  revenueOrderCountDataPointCode: string;
  revenuePreviousMonthDataPointCode: string | null;
  targetRisk: WalletSummaryTargetRisk | null;
  /** The seller's own active insights (`recipientUserId === sellerId`),
   * regardless of type — inactive customer, revenue drop, growth,
   * cross-sell, up-sell, insufficient mix, high stock/low turnover,
   * replenishment, churn risk, abandoned order. Ordered by estimated impact,
   * highest first (same ordering `evaluateInsights` already establishes). */
  insights: WalletSummaryInsightHighlight[];
  dataPoints: WalletSummaryDataPoint[];
}

/** Result of validating an LLM-generated summary against its own
 * {@link WalletSummaryPayload} — see
 * `wallet-summary-shared.ts`'s `validateGeneratedSummary` doc comment for the
 * full rejection rationale of each reason. */
export type WalletSummaryValidationOutcome =
  | { ok: true; citedDataPointCodes: string[] }
  | {
      ok: false;
      reason: 'missing_references' | 'unknown_reference' | 'hallucinated_number';
      detail: string;
    };

export type WalletSummaryStatus = 'ready' | 'error';

/** One resolved reference the UI renders as an expandable citation next to
 * the sentence(s) that cite it (`tasks.md`/TASK-186: "exibida na UI — nunca
 * um resumo sem rastreabilidade"). */
export interface WalletSummaryReference {
  code: string;
  label: string;
  value: string;
  unit: string | null;
}

/** The `organizations/{organizationId}/walletSummaries/{docId}` cache
 * document — never readable by any client directly (`firestore.rules` denies
 * it outright, same as `erpIntegration/credentials`); the only way a client
 * ever sees this data is through `generateWalletSummary`'s own response. */
export interface WalletSummaryCacheDoc {
  organizationId: string;
  companyId: string;
  sellerId: string;
  periodKey: string;
  status: WalletSummaryStatus;
  /** SHA-256 hex digest of the payload that produced (or attempted to
   * produce) this cache entry — a fresh call whose freshly-rebuilt payload
   * hashes differently never reuses this entry, even within the TTL
   * (`tasks.md`/TASK-186: "invalidação quando os dados mudam"). */
  payloadHash: string;
  summaryText: string | null;
  references: WalletSummaryReference[] | null;
  errorReason: string | null;
  provider: string | null;
  model: string | null;
  generatedAt: unknown;
  expiresAt: unknown;
  lastAttemptAt: unknown;
  requestedBy: string;
}
