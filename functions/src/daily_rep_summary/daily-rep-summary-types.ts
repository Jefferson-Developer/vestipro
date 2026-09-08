/**
 * Shared vocabulary for the daily rep summary feature (TASK-188, EPIC-28 —
 * "IA generativa: resumo diário do vendedor"). Same shape as
 * `../wallet_summary/wallet-summary-types.ts` (TASK-186) and
 * `../approach_suggestion/approach-suggestion-types.ts` (TASK-187): every
 * type here describes data already computed/persisted elsewhere in this
 * codebase (`sellerDailyAggregates`, TASK-133; `Insight`, TASK-121; `orders`,
 * TASK-095) — this module never introduces a new calculation, only a
 * read-only, LLM-facing projection of facts that already exist, each numeric
 * one tagged with a stable [DailyRepSummaryDataPoint.code] so the generated
 * text can cite exactly which one backs a claim.
 */

/**
 * One citable fact the LLM is allowed to reference in the generated text —
 * the *only* numbers
 * {@link import('./daily-rep-summary-shared').validateGeneratedDailyRepSummary}
 * ever accepts as legitimate.
 */
export interface DailyRepSummaryDataPoint {
  code: string;
  label: string;
  /** Human-readable, already-formatted value (e.g. `"1250.00"`, `"3"`) —
   * never re-formatted by the LLM prompt itself. */
  value: string;
  /** Same value as [value], parsed to a number — this is what
   * {@link import('./daily-rep-summary-shared').validateGeneratedDailyRepSummary}
   * actually compares every number found in the generated text against. */
  numericValue?: number;
  unit?: string;
}

/** One of the seller's own rejected orders still relevant today, reduced to
 * what the prompt needs — never the full `Order` document, so pricing
 * internals beyond the total amount never reach a third-party LLM provider.
 */
export interface DailyRepSummaryOrderIssueHighlight {
  orderId: string;
  orderNumber: string;
  customerName: string;
  reasonExcerpt: string | null;
  /** Code of the {@link DailyRepSummaryDataPoint} carrying this order's total
   * amount. */
  totalAmountDataPointCode: string;
}

/** One of the seller's own active insights (TASK-121), reduced to what this
 * prompt needs — mirrors `WalletSummaryInsightHighlight` (TASK-186). */
export interface DailyRepSummaryInsightHighlight {
  insightId: string;
  type: string;
  title: string;
  description: string;
  severity: string;
  customerId: string | null;
  customerName: string | null;
  dataPointCodes: string[];
}

/** Seller-below-target risk context (from the `sellerBelowTarget` insight,
 * TASK-131), present only when that insight is currently active for this
 * seller — mirrors `WalletSummaryTargetRisk` (TASK-186), whose own
 * `generateWalletSummary` already establishes the precedent of deriving this
 * section from the exact same insight/evidence for the seller's own summary.
 * `null` when the seller has no target registered or is on pace — never
 * fabricated. */
export interface DailyRepSummaryTargetRisk {
  insightId: string;
  title: string;
  description: string;
  targetValue: number;
  realizedValue: number;
  projectedAchievementPercentage: number;
  dataPointCodes: string[];
}

/** One follow-up/CRM task due today for the seller — always an empty array
 * today. `CrmTask` (TASK-152's "follow-up") has no Firestore/Outbox
 * persistence yet — it is still `SharedPreferencesCrmTaskRepository`
 * (local-only, on-device), exactly the same class of gap
 * `ApproachSuggestionPayload.recentOutcomeReason` already documents for
 * Opportunities (TASK-187). This type/field is kept (never removed) so a
 * future task that gives CrmTask real Firestore persistence can populate it
 * without a payload/prompt contract change. */
export interface DailyRepSummaryFollowUpHighlight {
  title: string;
  customerName: string | null;
  /** ISO 8601. */
  dueAt: string;
  overdue: boolean;
}

/**
 * The complete, structured, already-verified dataset `generateDailyRepSummary`
 * assembles server-side before ever calling an LLM provider — every fact
 * comes from already-computed, real, server-side data
 * (`sellerDailyAggregates`, `insights`, `orders`), scoped to
 * [organizationId]/[companyId]/[sellerId] by Firestore path/query alone.
 */
export interface DailyRepSummaryPayload {
  organizationId: string;
  companyId: string;
  sellerId: string;
  sellerName: string;
  /** `YYYY-MM-DD`, the calendar day (per the fixed `America/Sao_Paulo`
   * schedule timezone — same simplification every other scheduled Cloud
   * Function in this codebase already makes, e.g.
   * `generateInsightsScheduled`) this summary covers. */
  dateKey: string;
  todaysRevenueDataPointCode: string;
  todaysOrderCountDataPointCode: string;
  targetRisk: DailyRepSummaryTargetRisk | null;
  /** Rejected orders still relevant today, most recent first. */
  problemOrders: DailyRepSummaryOrderIssueHighlight[];
  /** The seller's own active insights (`recipientUserId === sellerId`),
   * ordered by estimated impact, highest first. */
  insights: DailyRepSummaryInsightHighlight[];
  /** Always empty today — see {@link DailyRepSummaryFollowUpHighlight}'s own
   * doc comment. */
  followUpsToday: DailyRepSummaryFollowUpHighlight[];
  dataPoints: DailyRepSummaryDataPoint[];
}

/** Result of validating an LLM-generated summary against its own
 * {@link DailyRepSummaryPayload} — see `daily-rep-summary-shared.ts`'s
 * `validateGeneratedDailyRepSummary` doc comment for the full rejection
 * rationale of each reason. */
export type DailyRepSummaryValidationOutcome =
  | { ok: true; citedDataPointCodes: string[] }
  | {
      ok: false;
      reason:
        | 'missing_references'
        | 'unknown_reference'
        | 'hallucinated_number'
        | 'forbidden_commercial_term';
      detail: string;
    };

/**
 * `ready` — text generated and validated; `empty` — nothing notable for this
 * seller today (no problem orders, no target risk, no insights, no sales),
 * so no LLM call was even attempted (never fabricates a summary out of
 * nothing) and no notification was dispatched; `error` — the provider call or
 * validation failed after one retry.
 */
export type DailyRepSummaryStatus = 'ready' | 'empty' | 'error';

/** One resolved reference the UI renders as an expandable citation next to
 * the sentence(s) that cite it. */
export interface DailyRepSummaryReference {
  code: string;
  label: string;
  value: string;
  unit: string | null;
}

/** The `organizations/{organizationId}/dailyRepSummaries/{docId}` cache/
 * history document — never readable by any client directly
 * (`firestore.rules` denies it outright, same as `walletSummaries`/
 * `approachSuggestions`); the only way a client ever sees this data is
 * through `getDailyRepSummary`'s own response. One document per
 * seller/day (`tasks.md`/TASK-188: "gerado uma vez por vendedor/dia
 * (idempotente)") — its mere existence for a given [dateKey] is what makes
 * `generateDailyRepSummary` idempotent for that day. */
export interface DailyRepSummaryCacheDoc {
  organizationId: string;
  companyId: string;
  sellerId: string;
  dateKey: string;
  status: DailyRepSummaryStatus;
  payloadHash: string;
  summaryText: string | null;
  references: DailyRepSummaryReference[] | null;
  errorReason: string | null;
  provider: string | null;
  model: string | null;
  generatedAt: unknown;
  /** Whether a `commercial`/`inApp` notification was actually created for
   * this entry — `false` for `empty`/`error`, or for a `ready` entry whose
   * recipient had the category/channel disabled at generation time. Read by
   * nothing today; kept for observability/debugging idempotency issues. */
  notificationDispatched: boolean;
}
