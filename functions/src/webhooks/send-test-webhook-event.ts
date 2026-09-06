import { logger } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { Timestamp, getFirestore } from 'firebase-admin/firestore';

import { resolveCorrelationId, type RequestWithMeta } from '../shared/callable-meta';
import { loadActiveMembership, requireNonEmptyString } from '../invites/invite-shared';
import {
  assertCanManageWebhooks,
  webhookConfigRef,
  webhookDeliveriesCollection,
} from './webhook-shared';

export interface SendTestWebhookEventRequest extends RequestWithMeta {
  organizationId?: string;
  webhookId?: string;
}

export interface SendTestWebhookEventResponse {
  correlationId: string;
  deliveryId: string;
}

/**
 * Enqueues a synthetic `webhook.test` delivery for exactly one webhook,
 * regardless of which real domain events it is subscribed to (TASK-170:
 * "Rotina de 'enviar evento de teste' para o gestor validar a configuração
 * antes de depender dela em produção") — deliberately bypasses
 * `enqueueWebhookEvent`'s "active + subscribed" fan-out matching, since a
 * gestor must be able to test a webhook even while it is still `isActive:
 * false` (still being set up) or does not (yet) subscribe to any real
 * event type.
 *
 * The actual HTTP delivery, signing and retry/backoff are handled by the
 * exact same `deliverWebhookEvent` trigger every real domain event goes
 * through — a test event is a real delivery in every respect except its
 * `data` payload and `isTest: true` flag, so a gestor validating it is
 * validating the real code path, not a simulation of it.
 */
export const sendTestWebhookEvent = onCall<
  SendTestWebhookEventRequest,
  Promise<SendTestWebhookEventResponse>
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

  const now = new Date();
  const deliveryRef = webhookDeliveriesCollection(db, organizationId).doc();
  await deliveryRef.set({
    organizationId,
    webhookId,
    // Each test send is its own, unique occurrence — never deduplicated
    // against a previous test (unlike a real domain event's deterministic
    // eventId), since a gestor pressing "enviar evento de teste" twice in a
    // row expects two independent deliveries, not one silently dropped.
    eventId: `test_${deliveryRef.id}`,
    eventType: 'webhook.test',
    data: {
      message: 'Evento de teste do VestiPro — sua configuração de webhook está funcionando.',
      triggeredBy: uid,
      triggeredAt: now.toISOString(),
    },
    isTest: true,
    status: 'pending',
    attempts: 0,
    lastError: null,
    lastResponseStatus: null,
    nextRetryAt: null,
    createdAt: Timestamp.fromDate(now),
    processedAt: null,
  });

  logger.info('sendTestWebhookEvent succeeded', {
    correlationId,
    uid,
    organizationId,
    webhookId,
    deliveryId: deliveryRef.id,
  });

  return { correlationId, deliveryId: deliveryRef.id };
});
