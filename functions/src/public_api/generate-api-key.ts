import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { getFirestore } from 'firebase-admin/firestore';

import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { loadActiveMembership, requireNonEmptyString } from '../invites/invite-shared';
import {
  apiKeysCollection,
  assertCanManageApiKeys,
  generateApiKeyToken,
  validateApiKeyScopes,
  validateRateLimitPerMinute,
} from './api-key-shared';
import type { ApiKeyScope } from './types';

export interface GenerateApiKeyRequest extends RequestWithMeta {
  organizationId?: string;
  name?: string;
  scopes?: unknown;
  rateLimitPerMinute?: number;
}

export interface GenerateApiKeyResponse {
  correlationId: string;
  keyId: string;
  scopes: ApiKeyScope[];
  rateLimitPerMinute: number;
  /** Present exactly once — the caller must display/copy it now; VestiPro
   * never re-exposes it after this response (only its SHA-256 hash is
   * persisted, `apiKeys/{keyId}.keyHash`), same "TTL curto/nunca reexibido"
   * contract `saveWebhookConfig`/`regenerateWebhookSecret` (TASK-170) already
   * document for the HMAC secret. */
  apiKey: string;
}

/**
 * Issues a brand-new public-API key for an organization (TASK-171): RBAC
 * (`assertCanManageApiKeys`, OWNER/ADMIN only) and every field re-validated
 * here from the caller's real Membership/request, independent of anything
 * the client claims — same posture `saveWebhookConfig`
 * (`webhooks/save-webhook-config.ts`, TASK-170) already documents. Never
 * updates an existing key in place; issuing a new one and revoking the old
 * (`revokeApiKey`) is the only supported way to replace one wholesale — see
 * `rotateApiKey` for keeping the same `keyId` while only replacing the
 * secret.
 */
export const generateApiKey = onCall<
  GenerateApiKeyRequest,
  Promise<GenerateApiKeyResponse>
>(async (request) => {
  const correlationId = resolveCorrelationId(request.data?._meta);
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Autenticação obrigatória.');
  }
  const uid = request.auth.uid;

  const organizationId = requireNonEmptyString(
    request.data?.organizationId,
    'organizationId',
  );
  const name = requireNonEmptyString(request.data?.name, 'name');

  const db = getFirestore();
  const membership = await loadActiveMembership(db, organizationId, uid);
  assertCanManageApiKeys(membership.roleName);

  const scopes = validateApiKeyScopes(request.data?.scopes);
  const rateLimitPerMinute = validateRateLimitPerMinute(request.data?.rateLimitPerMinute);

  const { token, tokenHash, suffix } = generateApiKeyToken();
  const now = new Date();
  const ref = apiKeysCollection(db, organizationId).doc();

  await ref.set({
    organizationId,
    name,
    keyHash: tokenHash,
    keySuffix: suffix,
    scopes,
    rateLimitPerMinute,
    status: 'active',
    createdAt: now,
    createdBy: uid,
    updatedAt: now,
    updatedBy: uid,
    revokedAt: null,
    revokedBy: null,
    lastUsedAt: null,
    lastRotatedAt: null,
  });

  logger.info('generateApiKey succeeded', {
    correlationId,
    uid,
    organizationId,
    keyId: ref.id,
    scopes,
  });

  return {
    correlationId,
    keyId: ref.id,
    scopes,
    rateLimitPerMinute,
    apiKey: token,
  };
});
