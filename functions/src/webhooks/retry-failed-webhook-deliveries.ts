import { logger } from 'firebase-functions/v2';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { Timestamp, getFirestore, type Firestore } from 'firebase-admin/firestore';

import { MAX_WEBHOOK_DELIVERY_ATTEMPTS, webhookDeliveriesCollection } from './webhook-shared';
import { claimWebhookDelivery, processClaimedWebhookDelivery } from './process-webhook-delivery';
import type { WebhookDeliveryDoc } from './types';

export interface RetryWebhookDeliverySummary {
  organizationsProcessed: number;
  deliveriesRetried: number;
}

/**
 * Reprocesses `failed` deliveries whose backoff window elapsed and whose
 * `attempts` is still under `MAX_WEBHOOK_DELIVERY_ATTEMPTS` (TASK-170) —
 * mirrors `retryFailedErpSyncItems` (TASK-169) end to end, including calling
 * `processClaimedWebhookDelivery` directly instead of recreating the
 * delivery document (recreating it would duplicate `webhookDeliveryLogs`
 * history and, since `deliverWebhookEvent` only triggers on document
 * *creation*, an in-place status update back to `pending` would never
 * re-fire it anyway). A delivery stuck at
 * `attempts >= MAX_WEBHOOK_DELIVERY_ATTEMPTS` is left `failed` forever
 * (`nextRetryAt: null`) — already surfaced as `healthStatus: 'failing'` on
 * its webhook config (TASK-170: "falha permanente é sinalizada
 * claramente").
 */
export const retryFailedWebhookDeliveries = onSchedule(
  {
    schedule: '* * * * *',
    timeZone: 'America/Sao_Paulo',
    region: 'southamerica-east1',
  },
  async () => {
    const summary = await retryFailedWebhookDeliveriesForAllOrganizations(
      getFirestore(),
      new Date(),
    );
    logger.info('retryFailedWebhookDeliveries finished', summary);
  },
);

export async function retryFailedWebhookDeliveriesForAllOrganizations(
  db: Firestore,
  now: Date,
): Promise<RetryWebhookDeliverySummary> {
  const organizationsSnapshot = await db.collection('organizations').get();
  let organizationsProcessed = 0;
  let deliveriesRetried = 0;

  for (const organizationDoc of organizationsSnapshot.docs) {
    const data = organizationDoc.data();
    if (data.deletedAt != null || data.status === 'inactive') continue;

    const dueSnapshot = await webhookDeliveriesCollection(db, organizationDoc.id)
      .where('status', '==', 'failed')
      .where('attempts', '<', MAX_WEBHOOK_DELIVERY_ATTEMPTS)
      .where('nextRetryAt', '<=', Timestamp.fromDate(now))
      .get();

    for (const deliveryDoc of dueSnapshot.docs) {
      const claimed = await claimWebhookDelivery(db, organizationDoc.id, deliveryDoc.id, [
        'failed',
      ]);
      if (!claimed) continue;
      await processClaimedWebhookDelivery(
        db,
        organizationDoc.id,
        deliveryDoc.id,
        claimed as WebhookDeliveryDoc,
        now,
      );
      deliveriesRetried += 1;
    }
    organizationsProcessed += 1;
  }

  return { organizationsProcessed, deliveriesRetried };
}
