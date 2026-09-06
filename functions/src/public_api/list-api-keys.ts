import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { Timestamp, getFirestore } from 'firebase-admin/firestore';

import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { loadActiveMembership, requireNonEmptyString } from '../invites/invite-shared';
import { apiKeysCollection, assertCanManageApiKeys } from './api-key-shared';
import type { ApiKeyScope, ApiKeyStatus } from './types';

export interface ListApiKeysRequest extends RequestWithMeta {
  organizationId?: string;
}

export interface ApiKeySummary {
  keyId: string;
  name: string;
  scopes: ApiKeyScope[];
  status: ApiKeyStatus;
  /** Last 4 characters of the plaintext key — the only part of it VestiPro
   * ever shows again after issuance/rotation (`generateApiKeyToken`). */
  keySuffix: string;
  rateLimitPerMinute: number;
  createdAt: string | null;
  lastUsedAt: string | null;
  lastRotatedAt: string | null;
  revokedAt: string | null;
}

export interface ListApiKeysResponse {
  correlationId: string;
  apiKeys: ApiKeySummary[];
}

/**
 * Lists every public-API key ever issued for an organization — metadata
 * only (`ApiKeySummary` never carries `keyHash`), the read path the future
 * gestor panel (out of scope for this task, see
 * `TASK-171-implementar-api-publica-CONCLUIDA.md`) is meant to call instead
 * of ever reading `apiKeys` directly from Firestore, which `firestore.rules`
 * denies outright for every client/role.
 */
export const listApiKeys = onCall<
  ListApiKeysRequest,
  Promise<ListApiKeysResponse>
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

  const db = getFirestore();
  const membership = await loadActiveMembership(db, organizationId, uid);
  assertCanManageApiKeys(membership.roleName);

  const snapshot = await apiKeysCollection(db, organizationId)
    .orderBy('createdAt', 'desc')
    .get();

  const apiKeys: ApiKeySummary[] = snapshot.docs.map((doc) => {
    const data = doc.data();
    return {
      keyId: doc.id,
      name: (data.name as string | undefined) ?? '',
      scopes: Array.isArray(data.scopes) ? (data.scopes as ApiKeyScope[]) : [],
      status: (data.status as ApiKeyStatus | undefined) ?? 'revoked',
      keySuffix: (data.keySuffix as string | undefined) ?? '',
      rateLimitPerMinute: (data.rateLimitPerMinute as number | undefined) ?? 0,
      createdAt: toIso(data.createdAt),
      lastUsedAt: toIso(data.lastUsedAt),
      lastRotatedAt: toIso(data.lastRotatedAt),
      revokedAt: toIso(data.revokedAt),
    };
  });

  return { correlationId, apiKeys };
});

function toIso(value: unknown): string | null {
  return value instanceof Timestamp ? value.toDate().toISOString() : null;
}
