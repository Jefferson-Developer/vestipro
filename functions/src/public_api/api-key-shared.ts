import { HttpsError } from 'firebase-functions/v2/https';
import {
  Timestamp,
  type DocumentData,
  type DocumentReference,
  type Firestore,
} from 'firebase-admin/firestore';

import { generateSecureToken, hashSecureToken } from '../shared/secure-token';
import { API_KEY_SCOPES, type ApiKeyScope } from './types';

/**
 * Shared by every public-REST-API Cloud Function (TASK-171, EPIC-22):
 * `generateApiKey`, `revokeApiKey`, `rotateApiKey`, `listApiKeys` and the
 * `publicApiV1` HTTPS router's own auth/rate-limit/usage-log middleware —
 * same "RBAC/vocabulary/validation defined exactly once" rationale
 * `webhook-shared.ts` (TASK-170) already documents.
 */

/** Mirrors `Capability.apiKeyManage` (`lib/core/permissions/capability.dart`)
 * — granted only to OWNER/ADMIN (`RolePermissionMatrix`'s full/near-full
 * sets), same restrictive scope as `WEBHOOK_MANAGE_ROLES`/
 * `ERP_INTEGRATION_ROLES`: issuing a credential an external system can use to
 * read/write an organization's commercial data is an infrastructure
 * decision, never delegated to
 * SALES_MANAGER/SALES_REP/SALES_ASSISTANT/FINANCE. */
export const API_KEY_MANAGE_ROLES: ReadonlySet<string> = new Set<string>([
  'OWNER',
  'ADMIN',
]);

export function assertCanManageApiKeys(roleName: string): void {
  if (!API_KEY_MANAGE_ROLES.has(roleName)) {
    throw new HttpsError(
      'permission-denied',
      'Seu perfil não pode gerenciar API keys.',
    );
  }
}

export function isApiKeyScope(value: string): value is ApiKeyScope {
  return (API_KEY_SCOPES as readonly string[]).includes(value);
}

/** Validates the list of scopes a new/rotated key is granted — non-empty,
 * every entry a known {@link ApiKeyScope}, no duplicates. Mirrors
 * `validateWebhookEvents` (`webhook-shared.ts`, TASK-170). */
export function validateApiKeyScopes(raw: unknown): ApiKeyScope[] {
  if (!Array.isArray(raw) || raw.length === 0) {
    throw new HttpsError(
      'invalid-argument',
      'scopes deve ser uma lista não vazia de escopos.',
    );
  }
  const seen = new Set<string>();
  const validated: ApiKeyScope[] = [];
  for (const value of raw) {
    if (typeof value !== 'string' || !isApiKeyScope(value)) {
      throw new HttpsError(
        'invalid-argument',
        `Escopo desconhecido em scopes: ${String(value)}.`,
      );
    }
    if (!seen.has(value)) {
      seen.add(value);
      validated.push(value);
    }
  }
  return validated;
}

export const DEFAULT_API_KEY_RATE_LIMIT_PER_MINUTE = 60;
export const MIN_API_KEY_RATE_LIMIT_PER_MINUTE = 1;
export const MAX_API_KEY_RATE_LIMIT_PER_MINUTE = 600;

/** `undefined` resolves to {@link DEFAULT_API_KEY_RATE_LIMIT_PER_MINUTE}; any
 * value out of `[1, 600]` (or non-integer) is rejected — a partner-facing
 * infrastructure knob, never left unbounded in either direction (an
 * accidental `0` would starve every request forever; an accidental very
 * large value would defeat the point of throttling one org's own traffic). */
export function validateRateLimitPerMinute(raw: unknown): number {
  if (raw === undefined) return DEFAULT_API_KEY_RATE_LIMIT_PER_MINUTE;
  if (
    typeof raw !== 'number' ||
    !Number.isInteger(raw) ||
    raw < MIN_API_KEY_RATE_LIMIT_PER_MINUTE ||
    raw > MAX_API_KEY_RATE_LIMIT_PER_MINUTE
  ) {
    throw new HttpsError(
      'invalid-argument',
      `rateLimitPerMinute deve ser um inteiro entre ${MIN_API_KEY_RATE_LIMIT_PER_MINUTE} e ${MAX_API_KEY_RATE_LIMIT_PER_MINUTE}.`,
    );
  }
  return raw;
}

/** Every plaintext API key handed to a partner is prefixed with this literal
 * — purely cosmetic (lets a partner/secret-scanner recognize a VestiPro key
 * at a glance, same idea as Stripe's `sk_live_`/GitHub's `ghp_`), carries no
 * cryptographic meaning of its own. */
export const API_KEY_PREFIX = 'vp_live_';

export interface GeneratedApiKey {
  /** Returned to the caller exactly once — never persisted, never
   * re-derivable from {@link GeneratedApiKey.tokenHash}. */
  token: string;
  /** SHA-256 hex digest of [token] — the only form ever persisted
   * (`apiKeys/{keyId}.keyHash`). */
  tokenHash: string;
  /** Last 4 characters of [token] — safe to persist/display verbatim
   * (`apiKeys/{keyId}.keySuffix`) so a gestor can recognize which physical
   * key is which in a list, without ever re-exposing the full secret. */
  suffix: string;
}

/** Generates a fresh, cryptographically random API key (256 bits of entropy,
 * via {@link generateSecureToken}) and its SHA-256 hash — the single
 * primitive `generateApiKey`/`rotateApiKey` both use, so a key's shape never
 * drifts between issuance and rotation. */
export function generateApiKeyToken(): GeneratedApiKey {
  const { token: rawToken } = generateSecureToken();
  const token = `${API_KEY_PREFIX}${rawToken}`;
  return {
    token,
    tokenHash: hashSecureToken(token),
    suffix: token.slice(-4),
  };
}

// ---------------------------------------------------------------------------
// Firestore path helpers — every public-API Cloud Function/middleware builds
// a path from these, so a path can never accidentally drift outside
// `organizations/{organizationId}/...` and leak across tenants.
// ---------------------------------------------------------------------------

export function apiKeysCollection(db: Firestore, organizationId: string) {
  return db
    .collection('organizations')
    .doc(organizationId)
    .collection('apiKeys');
}

export function apiKeyRef(db: Firestore, organizationId: string, keyId: string) {
  return apiKeysCollection(db, organizationId).doc(keyId);
}

export function apiKeyRateLimitBucketsCollection(
  db: Firestore,
  organizationId: string,
) {
  return db
    .collection('organizations')
    .doc(organizationId)
    .collection('apiKeyRateLimitBuckets');
}

export function apiUsageLogsCollection(db: Firestore, organizationId: string) {
  return db
    .collection('organizations')
    .doc(organizationId)
    .collection('apiUsageLogs');
}

export interface ApiKeyLookup {
  ref: DocumentReference;
  organizationRef: DocumentReference;
  data: DocumentData;
}

/**
 * Finds the (at most one) `apiKeys` document anywhere in Firestore whose
 * `keyHash` equals [tokenHash], via a `collectionGroup('apiKeys')` query —
 * mirrors `findInviteByTokenHash` (`invites/invite-shared.ts`, TASK-039)
 * exactly: the caller (an external partner presenting a raw `X-Api-Key`
 * header) only ever has the plaintext key, never the `organizationId` a
 * direct `organizations/{id}/apiKeys/{id}` lookup would need. The resolved
 * document's own `organizationId` field is the *only* source of truth this
 * codebase ever uses to scope a REST request to a tenant — never anything
 * the request body/query claims (TASK-171: "nunca aceitar organizationId
 * vindo do corpo/query da requisição como fonte de verdade").
 *
 * `keyHash` is a SHA-256 digest, so a match is effectively unique by
 * construction; `limit(1)` is still applied defensively.
 */
export async function findApiKeyByHash(
  db: Firestore,
  tokenHash: string,
): Promise<ApiKeyLookup | null> {
  const snapshot = await db
    .collectionGroup('apiKeys')
    .where('keyHash', '==', tokenHash)
    .limit(1)
    .get();

  if (snapshot.empty) {
    return null;
  }

  const document = snapshot.docs[0];
  const organizationRef = document.ref.parent.parent;
  if (!organizationRef) {
    throw new HttpsError(
      'internal',
      'API key document has no parent organization.',
    );
  }

  return { ref: document.ref, organizationRef, data: document.data() };
}

// ---------------------------------------------------------------------------
// Rate limiting — one fixed 1-minute window counter per (organization, key),
// enforced with a Firestore transaction so concurrent requests against the
// same key never both observe "under the limit" and both proceed
// (TASK-171: "Rate limit é sempre por organização/chave, nunca compartilhado
// globalmente entre organizações diferentes").
// ---------------------------------------------------------------------------

const RATE_LIMIT_WINDOW_MS = 60_000;
/** How long a rate-limit bucket document is kept around after its own
 * window closes — long enough for `resetAt` to always be in the past by
 * then, short enough to keep this collection from growing unbounded.
 * Actual deletion needs a Firestore TTL policy configured on
 * `apiKeyRateLimitBuckets.expiresAt` (via `gcloud`/console — TTL policies
 * are not expressible in `firestore.rules`/`firestore.indexes.json`), a
 * documented follow-up, not yet configured as of this task. */
const RATE_LIMIT_BUCKET_TTL_MS = RATE_LIMIT_WINDOW_MS * 5;

export function rateLimitBucketId(keyId: string, nowMs: number): string {
  const windowStart = Math.floor(nowMs / RATE_LIMIT_WINDOW_MS) * RATE_LIMIT_WINDOW_MS;
  return `${keyId}_${windowStart}`;
}

export interface RateLimitResult {
  allowed: boolean;
  limit: number;
  remaining: number;
  resetAt: Date;
}

/**
 * Atomically checks-and-increments the request counter for [keyId]'s current
 * 1-minute window, capped at [limitPerMinute]. Returns `allowed: false`
 * (without incrementing past the limit) once the window is exhausted — the
 * caller maps that into the standardized HTTP 429 response (TASK-171:
 * "resposta HTTP 429 padronizada e headers de limite restante").
 */
export async function checkAndConsumeRateLimit(
  db: Firestore,
  organizationId: string,
  keyId: string,
  limitPerMinute: number,
  now: Date = new Date(),
): Promise<RateLimitResult> {
  const nowMs = now.getTime();
  const windowStart = Math.floor(nowMs / RATE_LIMIT_WINDOW_MS) * RATE_LIMIT_WINDOW_MS;
  const resetAt = new Date(windowStart + RATE_LIMIT_WINDOW_MS);
  const bucketRef = apiKeyRateLimitBucketsCollection(db, organizationId).doc(
    rateLimitBucketId(keyId, nowMs),
  );

  const consumedCount = await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(bucketRef);
    const currentCount = asCount(snapshot.data()?.count);
    if (currentCount >= limitPerMinute) {
      return currentCount;
    }
    const nextCount = currentCount + 1;
    transaction.set(
      bucketRef,
      {
        organizationId,
        keyId,
        windowStart: Timestamp.fromMillis(windowStart),
        count: nextCount,
        expiresAt: Timestamp.fromMillis(windowStart + RATE_LIMIT_BUCKET_TTL_MS),
      },
      { merge: true },
    );
    return nextCount;
  });

  return {
    allowed: consumedCount <= limitPerMinute,
    limit: limitPerMinute,
    remaining: Math.max(limitPerMinute - consumedCount, 0),
    resetAt,
  };
}

function asCount(value: unknown): number {
  return typeof value === 'number' && Number.isFinite(value) ? value : 0;
}

// ---------------------------------------------------------------------------
// Usage log (TASK-171: "Log de uso da API por chave... para suporte e
// faturamento futuro").
// ---------------------------------------------------------------------------

export interface ApiUsageLogEntry {
  keyId: string;
  method: string;
  path: string;
  statusCode: number;
  latencyMs: number;
}

export async function logApiUsage(
  db: Firestore,
  organizationId: string,
  entry: ApiUsageLogEntry,
): Promise<void> {
  await apiUsageLogsCollection(db, organizationId).add({
    organizationId,
    ...entry,
    timestamp: Timestamp.now(),
  });
}

// ---------------------------------------------------------------------------
// Cursor pagination (TASK-171: "Paginação por cursor em todos os endpoints de
// listagem — nunca offset simples em coleções grandes"). Every listing
// endpoint orders by `(createdAt asc, __name__ asc)`; the cursor is an opaque,
// base64url-encoded pointer to the last item of the previous page.
// ---------------------------------------------------------------------------

export interface ListCursor {
  createdAtMs: number;
  id: string;
}

export function encodeCursor(cursor: ListCursor): string {
  return Buffer.from(JSON.stringify(cursor), 'utf8').toString('base64url');
}

/** Returns `null` for anything absent/malformed instead of throwing — an
 * invalid/tampered cursor is treated the same way an unknown/mistyped invite
 * token already is elsewhere in this codebase: an ordinary "start from the
 * beginning" case, never surfaced as a 500. */
export function decodeCursor(raw: string | undefined): ListCursor | null {
  if (!raw) return null;
  try {
    const decoded: unknown = JSON.parse(Buffer.from(raw, 'base64url').toString('utf8'));
    if (
      typeof decoded !== 'object' ||
      decoded === null ||
      typeof (decoded as Record<string, unknown>).createdAtMs !== 'number' ||
      typeof (decoded as Record<string, unknown>).id !== 'string'
    ) {
      return null;
    }
    const candidate = decoded as ListCursor;
    return { createdAtMs: candidate.createdAtMs, id: candidate.id };
  } catch {
    return null;
  }
}

export const DEFAULT_PAGE_SIZE = 20;
export const MAX_PAGE_SIZE = 100;

/** Parses the `?limit=` query parameter, defaulting/clamping to
 * `[1, MAX_PAGE_SIZE]` — never trusts an arbitrarily large partner-supplied
 * value that could otherwise turn one request into an unbounded full-
 * collection scan. */
export function parsePageSize(raw: unknown): number {
  const value = Array.isArray(raw) ? raw[0] : raw;
  const parsed = typeof value === 'string' ? Number(value) : NaN;
  if (!Number.isFinite(parsed) || !Number.isInteger(parsed) || parsed < 1) {
    return DEFAULT_PAGE_SIZE;
  }
  return Math.min(parsed, MAX_PAGE_SIZE);
}
