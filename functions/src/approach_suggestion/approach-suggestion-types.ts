/**
 * Shared vocabulary for the approach-suggestion feature (TASK-187, EPIC-28 —
 * "IA generativa: sugestão de abordagem comercial"). Same shape as
 * `../wallet_summary/wallet-summary-types.ts` (TASK-186): every type here
 * describes data already computed/stored elsewhere in this codebase (real
 * `orders`, real `crmActivities`, real `insights` — TASK-121) — this module
 * never introduces a new calculation, only a read-only, LLM-facing
 * projection of facts that already exist, each numeric one tagged with a
 * stable [ApproachSuggestionDataPoint.code] so the generated text can cite
 * exactly which one backs a claim (`tasks.md`/TASK-187: "Prompt template
 * restringe o modelo a gerar um roteiro de abordagem citando apenas fatos
 * presentes no payload").
 */

/**
 * One citable fact the LLM is allowed to reference in the generated text —
 * the *only* numbers
 * {@link import('./approach-suggestion-shared').validateGeneratedApproachSuggestion}
 * ever accepts as legitimate.
 */
export interface ApproachSuggestionDataPoint {
  code: string;
  label: string;
  /** Human-readable, already-formatted value (e.g. `"1250.00"`, `"3"`) —
   * never re-formatted by the LLM prompt itself. */
  value: string;
  /** Same value as [value], parsed to a number — this is what
   * {@link import('./approach-suggestion-shared').validateGeneratedApproachSuggestion}
   * actually compares every number found in the generated text against.
   * Omitted for the rare data point whose value is not itself a number. */
  numericValue?: number;
  unit?: string;
}

/** One of the customer's most recent real orders (any status), reduced to
 * what the prompt needs — never the full order document, so pricing
 * internals (discounts, payment terms) never reach a third-party LLM
 * provider (`tasks.md`/TASK-187: "Nunca sugerir desconto, condição comercial
 * ou preço"). */
export interface ApproachSuggestionOrderHighlight {
  orderNumber: string;
  /** ISO 8601. */
  submittedAt: string;
  statusLabel: string;
  itemCount: number;
  /** Code of the {@link ApproachSuggestionDataPoint} carrying this order's
   * total amount. */
  totalAmountDataPointCode: string;
}

/** One of the customer's most recent real CRM activities (TASK-059),
 * reduced to what the prompt needs. [descriptionExcerpt] is truncated
 * (never the seller's full free-text note verbatim beyond a safe length) so
 * a very long note cannot dominate the prompt or leak unrelated content. */
export interface ApproachSuggestionActivityHighlight {
  typeLabel: string;
  /** ISO 8601. */
  occurredAt: string;
  descriptionExcerpt: string;
}

/** One of the customer's own active insights (TASK-121), reduced to what
 * this prompt needs — never the full `Insight` shape, mirroring
 * `WalletSummaryInsightHighlight` (TASK-186). */
export interface ApproachSuggestionInsightHighlight {
  insightId: string;
  type: string;
  title: string;
  description: string;
  severity: string;
  impactAmount: number | null;
  impactPercentage: number | null;
  /** Codes of the {@link ApproachSuggestionDataPoint}s this insight
   * contributed, for the prompt to point the LLM at when narrating this
   * specific insight. */
  dataPointCodes: string[];
}

/**
 * The complete, structured, already-verified dataset a `suggestApproach`
 * call assembles server-side before ever calling an LLM provider —
 * `tasks.md`/TASK-187: "montando um payload estruturado: últimas compras,
 * atividades de CRM recentes, insights ativos do cliente, motivo de
 * perda/ganho recente quando houver". [recentOutcomeReason] is always `null`
 * today: win/loss reasons (TASK-061, `OpportunityOutcomeReason`) are
 * currently persisted client-side only (`SharedPreferencesOpportunityRepository`
 * — no Firestore-backed `OpportunityRepository` exists yet), so this Cloud
 * Function — which, like every other field here, only ever reads
 * already-verified server-side data, never a client-supplied free-text
 * field — has no reliable source to read one from. The field is kept (never
 * removed) so a future task that gives Opportunities real Firestore
 * persistence can populate it without a payload/prompt contract change.
 */
export interface ApproachSuggestionPayload {
  organizationId: string;
  companyId: string;
  customerId: string;
  customerName: string;
  customerSegment: string | null;
  customerPotential: string | null;
  /** Most recent real orders first (any status), newest first. */
  recentOrders: ApproachSuggestionOrderHighlight[];
  /** Most recent real CRM activities first, newest first. */
  recentActivities: ApproachSuggestionActivityHighlight[];
  /** The customer's own active insights, highest estimated impact first. */
  insights: ApproachSuggestionInsightHighlight[];
  /** Always `null` today — see this interface's own doc comment. */
  recentOutcomeReason: string | null;
  dataPoints: ApproachSuggestionDataPoint[];
}

/** Result of validating an LLM-generated approach suggestion against its own
 * {@link ApproachSuggestionPayload} — see
 * `approach-suggestion-shared.ts`'s `validateGeneratedApproachSuggestion` doc
 * comment for the full rejection rationale of each reason. */
export type ApproachSuggestionValidationOutcome =
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

export type ApproachSuggestionStatus = 'ready' | 'error';

/** One resolved reference the UI renders as an expandable citation next to
 * the sentence(s) that cite it. */
export interface ApproachSuggestionReference {
  code: string;
  label: string;
  value: string;
  unit: string | null;
}

/** The `organizations/{organizationId}/approachSuggestions/{customerId}`
 * cache document — never readable by any client directly (`firestore.rules`
 * denies it outright, same as `walletSummaries`); the only way a client ever
 * sees this data is through `suggestApproach`'s own response. */
export interface ApproachSuggestionCacheDoc {
  organizationId: string;
  companyId: string;
  customerId: string;
  status: ApproachSuggestionStatus;
  /** SHA-256 hex digest of the payload that produced (or attempted to
   * produce) this cache entry — a fresh call whose freshly-rebuilt payload
   * hashes differently never reuses this entry, even within the TTL. */
  payloadHash: string;
  suggestedText: string | null;
  references: ApproachSuggestionReference[] | null;
  errorReason: string | null;
  provider: string | null;
  model: string | null;
  generatedAt: unknown;
  expiresAt: unknown;
  lastAttemptAt: unknown;
  requestedBy: string;
}
