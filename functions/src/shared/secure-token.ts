import { createHash, randomBytes } from 'node:crypto';

/**
 * A freshly generated, cryptographically secure token together with its
 * SHA-256 hash — same shape/rationale as `invites/invite-shared.ts`'s
 * `GeneratedInviteToken`, factored out here so any Cloud Function that needs
 * an unguessable, server-only-generated token/link (TASK-081's
 * `createCatalogShareLink`, TASK-039's `createInvite`) can share the exact
 * same primitive instead of re-implementing `crypto.randomBytes` by hand.
 *
 * `invites/invite-shared.ts`'s own `generateInviteToken`/`hashInviteToken`
 * are deliberately left untouched (out of scope for this task, already
 * covered by their own tests) — new callers should prefer
 * {@link generateSecureToken}/{@link hashSecureToken} instead.
 */
export interface GeneratedSecureToken {
  token: string;
  tokenHash: string;
}

/** SHA-256 hex digest of [token] — the only form of a token ever persisted
 * to Firestore by any of its callers (never the plaintext). */
export function hashSecureToken(token: string): string {
  return createHash('sha256').update(token).digest('hex');
}

/**
 * Generates a non-guessable token (256 bits of entropy from
 * `crypto.randomBytes`, never `Math.random`/a sequential id) and its
 * SHA-256 hash. Only [GeneratedSecureToken.tokenHash] should ever be
 * persisted; [GeneratedSecureToken.token] is returned to the caller exactly
 * once, in the issuing callable's own response.
 */
export function generateSecureToken(): GeneratedSecureToken {
  const token = randomBytes(32).toString('base64url');
  return { token, tokenHash: hashSecureToken(token) };
}
