import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { getFirestore } from 'firebase-admin/firestore';

import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { loadActiveMembership, requireNonEmptyString } from '../invites/invite-shared';
import { apiKeyRef, assertCanManageApiKeys } from './api-key-shared';

export interface RevokeApiKeyRequest extends RequestWithMeta {
  organizationId?: string;
  keyId?: string;
}

export interface RevokeApiKeyResponse {
  correlationId: string;
  keyId: string;
}

/**
 * Immediately invalidates a public-API key (TASK-171: "API key revogada
 * invalida requisições imediatamente"). No TTL/cache is involved at all —
 * `authenticateApiKey` (`public_api/rest/middleware.ts`) re-reads
 * `apiKeys/{keyId}.status` straight from Firestore on every single request,
 * so a revocation here takes effect on the very next request, not after some
 * grace window.
 */
export const revokeApiKey = onCall<
  RevokeApiKeyRequest,
  Promise<RevokeApiKeyResponse>
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
  if (!snapshot.exists || snapshot.data()?.organizationId !== organizationId) {
    throw new HttpsError('not-found', 'API key não encontrada nesta organização.');
  }

  const now = new Date();
  await ref.set(
    {
      status: 'revoked',
      revokedAt: now,
      revokedBy: uid,
      updatedAt: now,
      updatedBy: uid,
    },
    { merge: true },
  );

  logger.info('revokeApiKey succeeded', { correlationId, uid, organizationId, keyId });

  return { correlationId, keyId };
});
