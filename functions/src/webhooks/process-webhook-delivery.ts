import { logger } from 'firebase-functions/v2';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import {
  Timestamp,
  getFirestore,
  type DocumentReference,
  type Firestore,
} from 'firebase-admin/firestore';

import {
  MAX_WEBHOOK_DELIVERY_ATTEMPTS,
  WEBHOOK_EVENT_ID_HEADER,
  WEBHOOK_EVENT_TYPE_HEADER,
  WEBHOOK_SIGNATURE_HEADER,
  nextWebhookRetryDelayMinutes,
  signWebhookPayload,
  webhookConfigRef,
  webhookDeliveriesCollection,
  webhookDeliveryLogsCollection,
  webhookSecretRef,
} from './webhook-shared';
import type { WebhookConfigDoc, WebhookDeliveryDoc, WebhookSecretDoc } from './types';

/** How long a single delivery attempt may take before it is treated as a
 * failure — a slow/hanging consumer must never stall this framework's retry
 * loop indefinitely. */
const DELIVERY_TIMEOUT_MS = 10_000;

/**
 * Claims a `pending`/`failed` delivery so it is never processed twice
 * concurrently — mirrors `claimErpSyncQueueItem` (TASK-169). Returns `null`
 * when there is nothing to claim.
 */
export async function claimWebhookDelivery(
  db: Firestore,
  organizationId: string,
  deliveryId: string,
  acceptedStatuses: readonly string[],
): Promise<WebhookDeliveryDoc | null> {
  const deliveryRef = webhookDeliveriesCollection(db, organizationId).doc(deliveryId);
  return db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(deliveryRef);
    if (!snapshot.exists) return null;
    const data = snapshot.data() as WebhookDeliveryDoc;
    if (!acceptedStatuses.includes(data.status)) return null;
    transaction.update(deliveryRef, { status: 'syncing' });
    return { ...data, status: 'syncing' };
  });
}

/**
 * The framework's actual delivery core (TASK-170) — shared, unmodified, by
 * the `onDocumentCreated` trigger below and `retryFailedWebhookDeliveries`'s
 * manual re-invocation, so there is exactly one place that decides how a
 * delivery is attempted, signed and retried. Never throws: every failure
 * path (missing config, missing secret, network error, non-2xx response) is
 * caught internally and reflected in the delivery's own
 * `status`/`attempts`/`lastError` plus a delivery-log entry, so one bad
 * delivery can never abort a batch nor the domain write that produced its
 * event (TASK-170: "disparo de webhook é sempre assíncrono e best-effort").
 */
export async function processClaimedWebhookDelivery(
  db: Firestore,
  organizationId: string,
  deliveryId: string,
  delivery: WebhookDeliveryDoc,
  now: Date,
  deliverFn: typeof deliverHttp = deliverHttp,
): Promise<void> {
  const deliveryRef = webhookDeliveriesCollection(db, organizationId).doc(deliveryId);
  const configRef = webhookConfigRef(db, organizationId, delivery.webhookId);

  const [configSnapshot, secretSnapshot] = await Promise.all([
    configRef.get(),
    webhookSecretRef(db, organizationId, delivery.webhookId).get(),
  ]);
  const config = configSnapshot.data() as WebhookConfigDoc | undefined;
  const secretDoc = secretSnapshot.data() as WebhookSecretDoc | undefined;

  if (!config || !secretDoc) {
    await markPermanentFailure(
      deliveryRef,
      configRef,
      delivery,
      now,
      'Webhook não encontrado ou removido.',
    );
    await logAttempt(db, organizationId, delivery, deliveryId, {
      requestUrl: config?.url ?? '',
      success: false,
      responseStatus: null,
      errorMessage: 'Webhook não encontrado ou removido.',
    }, now);
    return;
  }

  const rawBody = JSON.stringify({
    eventId: delivery.eventId,
    eventType: delivery.eventType,
    organizationId,
    data: delivery.data,
    timestamp: now.toISOString(),
  });
  const signature = signWebhookPayload(secretDoc.secret, rawBody);

  const attempt = (delivery.attempts ?? 0) + 1;
  let outcome: { success: boolean; responseStatus: number | null; errorMessage: string | null };
  try {
    const responseStatus = await deliverFn(config.url, rawBody, {
      [WEBHOOK_SIGNATURE_HEADER]: signature,
      [WEBHOOK_EVENT_ID_HEADER]: delivery.eventId,
      [WEBHOOK_EVENT_TYPE_HEADER]: delivery.eventType,
      'Content-Type': 'application/json',
    });
    const success = responseStatus >= 200 && responseStatus < 300;
    outcome = {
      success,
      responseStatus,
      errorMessage: success ? null : `Endpoint retornou HTTP ${responseStatus}.`,
    };
  } catch (error) {
    outcome = {
      success: false,
      responseStatus: null,
      errorMessage: error instanceof Error ? error.message : 'Erro de rede desconhecido.',
    };
  }

  if (outcome.success) {
    await deliveryRef.update({
      status: 'synced',
      attempts: attempt,
      lastError: null,
      lastResponseStatus: outcome.responseStatus,
      nextRetryAt: null,
      processedAt: Timestamp.fromDate(now),
    });
    await configRef.update({
      healthStatus: 'ok',
      consecutiveFailureCount: 0,
      lastSuccessAt: Timestamp.fromDate(now),
    });
  } else if (attempt < MAX_WEBHOOK_DELIVERY_ATTEMPTS) {
    await deliveryRef.update({
      status: 'failed',
      attempts: attempt,
      lastError: outcome.errorMessage,
      lastResponseStatus: outcome.responseStatus,
      nextRetryAt: Timestamp.fromDate(
        new Date(now.getTime() + nextWebhookRetryDelayMinutes(attempt) * 60_000),
      ),
      processedAt: Timestamp.fromDate(now),
    });
  } else {
    await markPermanentFailure(deliveryRef, configRef, { ...delivery, attempts: attempt }, now, outcome.errorMessage);
  }

  await logAttempt(db, organizationId, delivery, deliveryId, {
    requestUrl: config.url,
    success: outcome.success,
    responseStatus: outcome.responseStatus,
    errorMessage: outcome.errorMessage,
  }, now, attempt);

  logger.info('processWebhookDelivery finished', {
    organizationId,
    deliveryId,
    webhookId: delivery.webhookId,
    eventType: delivery.eventType,
    attempt,
    success: outcome.success,
  });
}

async function markPermanentFailure(
  deliveryRef: DocumentReference,
  configRef: DocumentReference,
  delivery: WebhookDeliveryDoc,
  now: Date,
  errorMessage: string | null,
): Promise<void> {
  await deliveryRef.update({
    status: 'failed',
    attempts: delivery.attempts ?? MAX_WEBHOOK_DELIVERY_ATTEMPTS,
    lastError: errorMessage,
    // `nextRetryAt: null` at max attempts is exactly what marks a delivery
    // as *permanently* failed (never picked up again by
    // `retryFailedWebhookDeliveries`'s `nextRetryAt <= now` query) — mirrors
    // `processClaimedErpSyncQueueItem`'s same convention (TASK-169).
    nextRetryAt: null,
    processedAt: Timestamp.fromDate(now),
  });
  // Best-effort — a webhook config already deleted concurrently with this
  // delivery is not itself an error worth failing this call over.
  await configRef
    .update({
      healthStatus: 'failing',
      consecutiveFailureCount: (delivery.attempts ?? 0),
      lastFailureAt: Timestamp.fromDate(now),
    })
    .catch(() => undefined);
}

async function logAttempt(
  db: Firestore,
  organizationId: string,
  delivery: WebhookDeliveryDoc,
  deliveryId: string,
  outcome: { requestUrl: string; success: boolean; responseStatus: number | null; errorMessage: string | null },
  now: Date,
  attempt = 0,
): Promise<void> {
  await webhookDeliveryLogsCollection(db, organizationId).add({
    organizationId,
    webhookId: delivery.webhookId,
    deliveryId,
    eventId: delivery.eventId,
    eventType: delivery.eventType,
    attempt,
    requestUrl: outcome.requestUrl,
    success: outcome.success,
    responseStatus: outcome.responseStatus,
    errorMessage: outcome.errorMessage,
    createdAt: Timestamp.fromDate(now),
  });
}

/** The real HTTP delivery — isolated behind `deliverFn` in
 * `processClaimedWebhookDelivery` so unit tests can substitute a fake
 * transport instead of performing real network I/O. */
async function deliverHttp(
  url: string,
  rawBody: string,
  headers: Record<string, string>,
): Promise<number> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), DELIVERY_TIMEOUT_MS);
  try {
    const response = await fetch(url, {
      method: 'POST',
      headers,
      body: rawBody,
      signal: controller.signal,
    });
    return response.status;
  } finally {
    clearTimeout(timeout);
  }
}

/**
 * Fires once per `webhookDeliveries` document creation — `enqueueWebhookEvent`
 * / `sendTestWebhookEvent` are the only code that ever creates one, always
 * with `status: 'pending'`, so this trigger only ever needs to claim
 * `'pending'`. Every delivery is its own document/invocation: one delivery
 * throwing never touches any other delivery's document (TASK-170: "Falha
 * permanente de entrega não pode travar nem atrasar o fluxo interno").
 */
export const deliverWebhookEvent = onDocumentCreated(
  'organizations/{organizationId}/webhookDeliveries/{deliveryId}',
  async (event) => {
    const { organizationId, deliveryId } = event.params;
    const db = getFirestore();
    const claimed = await claimWebhookDelivery(db, organizationId, deliveryId, ['pending']);
    if (!claimed) return;
    await processClaimedWebhookDelivery(db, organizationId, deliveryId, claimed, new Date());
  },
);
