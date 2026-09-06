import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { getFirestore } from 'firebase-admin/firestore';

import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { loadActiveMembership, requireNonEmptyString } from '../invites/invite-shared';
import {
  assertCanManageErpIntegration,
  erpIntegrationCredentialsRef,
} from './erp-integration-shared';

export interface SaveErpIntegrationCredentialsRequest extends RequestWithMeta {
  organizationId?: string;
  secrets?: unknown;
}

export interface SaveErpIntegrationCredentialsResponse {
  correlationId: string;
}

/**
 * Saves an organization's ERP credentials (TASK-169) — a document
 * `firestore.rules` denies `read`/`write` on outright for every client, so
 * this callable (Admin SDK) is the only way in, and there is no matching
 * "get credentials" callable at all: once saved, a secret is only ever read
 * back by this feature's own Cloud Functions (`loadErpIntegrationCredentials`)
 * to build a request to the ERP, never returned to any client, never logged.
 *
 * `secrets` is an opaque `Record<string, string>` — its shape (e.g.
 * `bearerToken` for the reference `GenericRestErpAdapter`) is adapter-
 * specific, so it deliberately is not validated against a fixed key list
 * here; every value must be a non-empty string, and that is all this
 * callable ever asserts about it.
 */
export const saveErpIntegrationCredentials = onCall<
  SaveErpIntegrationCredentialsRequest,
  Promise<SaveErpIntegrationCredentialsResponse>
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
  assertCanManageErpIntegration(membership.roleName);

  const secrets = assertValidSecrets(request.data?.secrets);

  await erpIntegrationCredentialsRef(db, organizationId).set({
    organizationId,
    secrets,
    updatedAt: new Date(),
    updatedBy: uid,
  });

  // Deliberately never logs `secrets` (not even its keys' names, which could
  // hint at the adapter's auth shape) — only that the operation happened.
  logger.info('saveErpIntegrationCredentials succeeded', {
    correlationId,
    uid,
    organizationId,
  });

  return { correlationId };
});

function assertValidSecrets(raw: unknown): Record<string, string> {
  if (raw === null || typeof raw !== 'object' || Array.isArray(raw)) {
    throw new HttpsError('invalid-argument', 'secrets deve ser um objeto.');
  }
  const entries = Object.entries(raw as Record<string, unknown>);
  if (entries.length === 0) {
    throw new HttpsError('invalid-argument', 'secrets não pode ser vazio.');
  }
  const validated: Record<string, string> = {};
  for (const [key, value] of entries) {
    if (typeof value !== 'string' || value.trim().length === 0) {
      throw new HttpsError(
        'invalid-argument',
        `Credencial "${key}" deve ser uma string não vazia.`,
      );
    }
    validated[key] = value;
  }
  return validated;
}
