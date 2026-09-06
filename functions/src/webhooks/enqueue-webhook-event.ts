import { Timestamp, type Firestore } from 'firebase-admin/firestore';

import {
  computeWebhookEventId,
  webhookConfigsCollection,
  webhookDeliveriesCollection,
} from './webhook-shared';
import type { EnqueueWebhookEventParams, WebhookConfigDoc } from './types';

export interface EnqueueWebhookEventResult {
  eventId: string;
  /** One entry per active webhook subscribed to `eventType` — `deduped:
   * true` when an equivalent delivery (same webhook + eventId) was already
   * queued/in flight/delivered and this call was a no-op for that webhook. */
  deliveries: ReadonlyArray<{ webhookId: string; deliveryId: string; deduped: boolean }>;
}

/**
 * The single entry point that ever creates a `webhookDeliveries` document
 * (TASK-170) — every domain trigger (`enqueueOrderWebhookEvents`,
 * `enqueueCustomerWebhookEvents`, `enqueueInventoryWebhookEvents`) calls
 * this, so there is exactly one place that decides which of an
 * organization's *active* webhooks are subscribed to a given event and
 * fans the event out to each of them, with the exact same idempotency
 * guarantee every time.
 *
 * Deliberately scoped to a single `organizationId` throughout — never reads
 * or writes any other organization's `webhooks`/`webhookDeliveries`
 * subcollection (TASK-170: "Payload de webhook nunca inclui dados de outra
 * organização").
 *
 * Never throws: every domain trigger that calls this must remain
 * best-effort with respect to the webhook framework (TASK-170: "disparo de
 * webhook é sempre assíncrono e best-effort do ponto de vista do fluxo
 * principal") — a Firestore error here is left for the caller to catch and
 * log, never allowed to fail the write that produced the domain event.
 */
export async function enqueueWebhookEvent(
  db: Firestore,
  params: EnqueueWebhookEventParams,
): Promise<EnqueueWebhookEventResult> {
  const eventId = computeWebhookEventId({
    organizationId: params.organizationId,
    eventType: params.eventType,
    entityId: params.entityId,
    sourceVersion: params.sourceVersion,
  });

  const configsSnapshot = await webhookConfigsCollection(db, params.organizationId)
    .where('isActive', '==', true)
    .where('events', 'array-contains', params.eventType)
    .get();

  const deliveriesCollection = webhookDeliveriesCollection(db, params.organizationId);
  const deliveries: Array<{ webhookId: string; deliveryId: string; deduped: boolean }> = [];

  for (const configDoc of configsSnapshot.docs) {
    const config = configDoc.data() as WebhookConfigDoc;
    if (config.organizationId !== params.organizationId) {
      // Defensive only — `webhookConfigsCollection` is already scoped to
      // this exact organization's subcollection, so this can never actually
      // differ; kept as an explicit guard against a future refactor
      // accidentally widening the query.
      continue;
    }

    const existing = await deliveriesCollection
      .where('webhookId', '==', configDoc.id)
      .where('eventId', '==', eventId)
      .where('status', 'in', ['pending', 'syncing', 'synced'])
      .limit(1)
      .get();
    if (!existing.empty) {
      deliveries.push({
        webhookId: configDoc.id,
        deliveryId: existing.docs[0].id,
        deduped: true,
      });
      continue;
    }

    const deliveryRef = deliveriesCollection.doc();
    await deliveryRef.set({
      organizationId: params.organizationId,
      webhookId: configDoc.id,
      eventId,
      eventType: params.eventType,
      data: params.data,
      isTest: false,
      status: 'pending',
      attempts: 0,
      lastError: null,
      lastResponseStatus: null,
      nextRetryAt: null,
      createdAt: Timestamp.fromDate(params.now),
      processedAt: null,
    });
    deliveries.push({ webhookId: configDoc.id, deliveryId: deliveryRef.id, deduped: false });
  }

  return { eventId, deliveries };
}
