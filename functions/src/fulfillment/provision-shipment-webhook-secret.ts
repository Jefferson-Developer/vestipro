import { Timestamp, getFirestore } from 'firebase-admin/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

import { loadActiveMembership, requireNonEmptyString } from '../invites/invite-shared';
import { generateWebhookSecret } from '../webhooks/webhook-shared';

export interface ProvisionShipmentWebhookSecretRequest {
  organizationId?: string;
  carrierId?: string;
}

export interface ProvisionShipmentWebhookSecretResponse {
  carrierId: string;
  secret: string;
}

/**
 * OWNER/ADMIN-only callable (re)generating the per-`carrierId` HMAC secret
 * `handleShipmentTrackingWebhook` verifies every inbound delivery against
 * (TASK-214, EPIC-32) — same "generate once, show once, never re-display"
 * shape `regenerateWebhookSecret` (TASK-170) already establishes; the raw
 * value is only ever returned in this one response, never re-readable
 * afterwards (`firestore.rules`: `shipmentWebhookSecrets` denies every client
 * read).
 */
export const provisionShipmentWebhookSecret = onCall<
  ProvisionShipmentWebhookSecretRequest,
  Promise<ProvisionShipmentWebhookSecretResponse>
>(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'É necessário estar autenticado.');
  }
  const uid = request.auth.uid;
  const organizationId = requireNonEmptyString(request.data?.organizationId, 'organizationId');
  const carrierId = requireNonEmptyString(request.data?.carrierId, 'carrierId');

  const db = getFirestore();
  const membership = await loadActiveMembership(db, organizationId, uid);
  if (membership.roleName !== 'OWNER' && membership.roleName !== 'ADMIN') {
    throw new HttpsError('permission-denied', 'Apenas OWNER/ADMIN podem configurar este webhook.');
  }

  const secret = generateWebhookSecret();
  await db
    .collection('organizations')
    .doc(organizationId)
    .collection('shipmentWebhookSecrets')
    .doc(carrierId)
    .set({
      organizationId,
      carrierId,
      secret,
      updatedAt: Timestamp.now(),
      updatedBy: uid,
    });

  return { carrierId, secret };
});
