import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { getFirestore } from 'firebase-admin/firestore';

import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { loadActiveMembership, requireNonEmptyString } from '../invites/invite-shared';
import {
  assertCanManageWebhooks,
  generateWebhookSecret,
  validateWebhookEvents,
  validateWebhookUrl,
  webhookConfigRef,
  webhookConfigsCollection,
  webhookSecretRef,
} from './webhook-shared';

export interface SaveWebhookConfigRequest extends RequestWithMeta {
  organizationId?: string;
  /** Absent (or empty) creates a new webhook; present updates the existing
   * one — same create-or-update shape as `saveErpIntegrationConfig`
   * (TASK-169), except a webhook config additionally needs an id to update,
   * since an organization may have more than one. */
  webhookId?: string;
  url?: string;
  events?: unknown;
  isActive?: boolean;
}

export interface SaveWebhookConfigResponse {
  correlationId: string;
  webhookId: string;
  /** Only ever present on creation (or secret regeneration, see
   * `regenerateWebhookSecret`) — TASK-170: "Segredo HMAC nunca é reexibido
   * em texto claro após a criação inicial". `undefined` on every update of
   * an existing webhook. */
  secret?: string;
}

/**
 * Creates or updates the non-secret half of an organization's webhook
 * (TASK-170): destination URL, subscribed events, active/inactive toggle.
 * Never accepts/returns the HMAC secret on update — a brand-new webhook
 * gets one generated here, returned exactly once; an existing webhook keeps
 * whatever secret `regenerateWebhookSecret` last set.
 *
 * RBAC (`assertCanManageWebhooks`, OWNER/ADMIN only) and every field's shape
 * are re-validated here from the caller's real Membership/request,
 * independent of anything the client claims — same posture
 * `saveErpIntegrationConfig` (TASK-169) already documents.
 */
export const saveWebhookConfig = onCall<
  SaveWebhookConfigRequest,
  Promise<SaveWebhookConfigResponse>
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
  assertCanManageWebhooks(membership.roleName);

  const url = validateWebhookUrl(request.data?.url);
  const events = validateWebhookEvents(request.data?.events);
  const isActive = request.data?.isActive !== false;
  const now = new Date();

  const requestedWebhookId = request.data?.webhookId?.trim();
  const isCreate = !requestedWebhookId;
  const webhookRef = isCreate
    ? webhookConfigsCollection(db, organizationId).doc()
    : webhookConfigRef(db, organizationId, requestedWebhookId as string);

  if (!isCreate) {
    const existing = await webhookRef.get();
    if (!existing.exists || existing.data()?.organizationId !== organizationId) {
      throw new HttpsError('not-found', 'Webhook não encontrado nesta organização.');
    }
  }

  await webhookRef.set(
    {
      organizationId,
      url,
      events,
      isActive,
      ...(isCreate
        ? {
            healthStatus: 'ok',
            consecutiveFailureCount: 0,
            lastFailureAt: null,
            lastSuccessAt: null,
            createdAt: now,
            createdBy: uid,
          }
        : {}),
      updatedAt: now,
      updatedBy: uid,
    },
    { merge: true },
  );

  let secret: string | undefined;
  if (isCreate) {
    secret = generateWebhookSecret();
    await webhookSecretRef(db, organizationId, webhookRef.id).set({
      organizationId,
      webhookId: webhookRef.id,
      secret,
      updatedAt: now,
      updatedBy: uid,
    });
  }

  logger.info('saveWebhookConfig succeeded', {
    correlationId,
    uid,
    organizationId,
    webhookId: webhookRef.id,
    isCreate,
  });

  return { correlationId, webhookId: webhookRef.id, secret };
});
