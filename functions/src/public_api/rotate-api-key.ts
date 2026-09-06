import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { getFirestore } from 'firebase-admin/firestore';

import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { loadActiveMembership, requireNonEmptyString } from '../invites/invite-shared';
import { apiKeyRef, assertCanManageApiKeys, generateApiKeyToken } from './api-key-shared';

export interface RotateApiKeyRequest extends RequestWithMeta {
  organizationId?: string;
  keyId?: string;
}

export interface RotateApiKeyResponse {
  correlationId: string;
  keyId: string;
  /** Present exactly once — same "never re-readable after this response"
   * contract as `generateApiKey`. */
  apiKey: string;
}

/**
 * Rotates an existing, still-active public-API key's secret in place
 * (TASK-171) — the same `keyId`/`name`/`scopes`/`rateLimitPerMinute` keep
 * working, only the plaintext credential a partner presents changes. The
 * only way to recover from a leaked/lost key without also having to update
 * every other configuration (scopes, rate limit) a partner integration
 * depends on — mirrors `regenerateWebhookSecret` (TASK-170)'s exact
 * rationale for webhooks. A revoked key can never be rotated back into life
 * this way — `generateApiKey` a brand-new one instead — so `revokeApiKey`'s
 * "invalida requisições imediatamente" guarantee is never quietly undone by
 * a rotation.
 */
export const rotateApiKey = onCall<
  RotateApiKeyRequest,
  Promise<RotateApiKeyResponse>
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
  const keyId = requireNonEmptyString(request.data?.keyId, 'keyId');

  const db = getFirestore();
  const membership = await loadActiveMembership(db, organizationId, uid);
  assertCanManageApiKeys(membership.roleName);

  const ref = apiKeyRef(db, organizationId, keyId);
  const snapshot = await ref.get();
  const existing = snapshot.data();
  if (!snapshot.exists || !existing || existing.organizationId !== organizationId) {
    throw new HttpsError('not-found', 'API key não encontrada nesta organização.');
  }
  if (existing.status !== 'active') {
    throw new HttpsError(
      'failed-precondition',
      'Uma API key revogada não pode ser rotacionada; gere uma nova chave.',
    );
  }

  const { token, tokenHash, suffix } = generateApiKeyToken();
  const now = new Date();
  await ref.set(
    {
      keyHash: tokenHash,
      keySuffix: suffix,
      lastRotatedAt: now,
      updatedAt: now,
      updatedBy: uid,
    },
    { merge: true },
  );

  logger.info('rotateApiKey succeeded', { correlationId, uid, organizationId, keyId });

  return { correlationId, keyId, apiKey: token };
});
