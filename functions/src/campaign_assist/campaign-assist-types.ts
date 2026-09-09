/**
 * Shared vocabulary for the campaign-creation-assist feature (TASK-192,
 * EPIC-28 — "IA generativa: criação assistida de coleção/campanha"). Same
 * shape as `../approach_suggestion/approach-suggestion-types.ts`
 * (TASK-187)/`../report_explanation/report-explanation-types.ts` (TASK-189):
 * every type here describes data already resolved elsewhere in this codebase
 * (real `organizations/{organizationId}/products` documents — TASK-064) or a
 * parameter the admin explicitly typed — this module never introduces a new
 * calculation, only a read-only, LLM-facing projection of facts/parameters
 * that already exist.
 */

/** One real product the admin selected to associate with the campaign being
 * drafted — reduced to what the prompt needs. Deliberately never carries
 * price/discount/stock fields: the LLM prompt this feeds never sees pricing
 * data at all (`tasks.md`/TASK-192: "Geração nunca cria preço, desconto ou
 * condição comercial"). */
export interface CampaignAssistProductReference {
  productId: string;
  name: string;
  categoryName: string | null;
  collectionName: string | null;
}

/**
 * The complete, structured, already-verified dataset an
 * `assistCampaignCreation` call assembles server-side before ever calling an
 * LLM provider. [productReferences] only ever contains products that were
 * independently re-resolved from this organization's own `products`
 * collection by id — never a name/category/collection string the client
 * claims directly (`tasks.md`/TASK-192: "Payload enviado ao modelo restrito
 * aos dados da organização do admin autenticado").
 */
export interface CampaignAssistPayload {
  organizationId: string;
  /** Free text describing the intended audience, as typed by the admin —
   * always truncated to `CAMPAIGN_ASSIST_MAX_AUDIENCE_LENGTH` before this
   * payload is built, same "never trust free-text length" precedent as
   * `ApproachSuggestionActivityHighlight.descriptionExcerpt` (TASK-187). */
  audienceDescription: string;
  /** Desired tone of voice, as typed by the admin — always truncated to
   * `CAMPAIGN_ASSIST_MAX_TONE_LENGTH`. */
  tone: string;
  /** Human-readable period label (e.g. `"01/12/2026 a 31/01/2027"`), or
   * `null` when the admin has not set a period yet — never a raw ISO string
   * the LLM would have to reformat itself. */
  periodLabel: string | null;
  /** The real products the admin selected — `[]` is valid: a campaign can be
   * a broad seasonal narrative with no specific product singled out yet. */
  productReferences: CampaignAssistProductReference[];
}

/** Result of validating an LLM-generated campaign draft against its own
 * {@link CampaignAssistPayload} — see `campaign-assist-shared.ts`'s
 * `validateGeneratedCampaignAssist` doc comment for the full rejection
 * rationale of each reason. */
export type CampaignAssistValidationOutcome =
  | {
      ok: true;
      title: string;
      subtitle: string;
      description: string;
      citedProductIds: string[];
    }
  | {
      ok: false;
      reason:
        | 'invalid_json'
        | 'invalid_shape'
        | 'unknown_reference'
        | 'unreferenced_citation'
        | 'forbidden_commercial_term';
      detail: string;
    };

export type CampaignAssistStatus = 'ready' | 'error';

/** The `organizations/{organizationId}/campaignAssistDrafts/{cacheKey}`
 * cache document — never readable by any client directly (`firestore.rules`
 * denies it outright, same as `walletSummaries`/`approachSuggestions`); the
 * only way a client ever sees this data is through `assistCampaignCreation`'s
 * own response. */
export interface CampaignAssistCacheDoc {
  organizationId: string;
  requestedBy: string;
  status: CampaignAssistStatus;
  /** SHA-256 hex digest of the payload that produced (or attempted to
   * produce) this cache entry — a fresh call whose freshly-rebuilt payload
   * hashes differently never reuses this entry, even within the TTL. */
  payloadHash: string;
  title: string | null;
  subtitle: string | null;
  description: string | null;
  citedProductIds: string[] | null;
  errorReason: string | null;
  provider: string | null;
  model: string | null;
  generatedAt: unknown;
  expiresAt: unknown;
  lastAttemptAt: unknown;
}
