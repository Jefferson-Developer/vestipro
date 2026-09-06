import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { getFirestore } from 'firebase-admin/firestore';

import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { loadActiveMembership, requireNonEmptyString } from '../invites/invite-shared';
import {
  assertCanManageWebhooks,
  generateWebhookSecret,
  webhookConfigRef,
  webhookSecretRef,
} from './webhook-shared';

export interface RegenerateWebhookSecretRequest extends RequestWithMeta {
  organizationId?: string;
  webhookId?: string;
}

export interface RegenerateWebhookSecretResponse {
  correlationId: string;
  /** Present exactly once — the caller must display/copy it now; VestiPro
   * never shows it again after this response (TASK-170). */
  secret: string;
}

/**
 * Rotates an existing webhook's HMAC secret (TASK-170) — the only way to
 * recover from a leaked/lost secret, since a secret is never re-readable
 * once set (`firestore.rules` denies `webhookSecrets` read/write outright
 * for every client). Every delivery signed with the old secret that is
 * still in flight when this runs keeps using whatever secret
 * `processClaimedWebhookDelivery` reads at the moment it actually attempts
 * delivery — there is no separate "grace period" for the old secret, same
 * simplicity `saveErpIntegrationCredentials` (TASK-169) accepts for ERP
 * credential rotation.
 */
export const regenerateWebhookSecret = onCall<
  RegenerateWebhookSecretRequest,
  Promise<RegenerateWebhookSecretResponse>
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
  const webhookId = requireNonEmptyString(request.data?.webhookId, 'webhookId');

  const db = getFirestore();
  const membership = await loadActiveMembership(db, organizationId, uid);
  assertCanManageWebhooks(membership.roleName);

  const configSnapshot = await webhookConfigRef(db, organizationId, webhookId).get();
  if (!configSnapshot.exists || configSnapshot.data()?.organizationId !== organizationId) {
    throw new HttpsError('not-found', 'Webhook não encontrado nesta organização.');
  }

  const secret = generateWebhookSecret();
  const now = new Date();
  await webhookSecretRef(db, organizationId, webhookId).set({
    organizationId,
    webhookId,
    secret,
    updatedAt: now,
    updatedBy: uid,
  });

  logger.info('regenerateWebhookSecret succeeded', {
    correlationId,
    uid,
    organizationId,
    webhookId,
  });

  return { correlationId, secret };
});
