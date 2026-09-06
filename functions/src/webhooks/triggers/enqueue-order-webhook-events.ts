import { logger } from 'firebase-functions/v2';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { getFirestore, type DocumentData } from 'firebase-admin/firestore';

import { enqueueWebhookEvent } from '../enqueue-webhook-event';

/**
 * Produces `order.created`/`order.status_changed` webhook events (TASK-170)
 * from the exact same `orders` collection write every other order-driven
 * side effect (`recomputeSalesDailyOnOrderWrite`, TASK-133) already listens
 * to — a dedicated `onDocumentWritten` trigger, entirely independent of
 * (and never blocking) that other trigger or the order write itself
 * (TASK-170: "disparo de webhook é sempre assíncrono e best-effort").
 *
 * Deliberately sends only a minimal, non-financial subset of the order to
 * an outbound webhook (id/customer/seller/orderNumber/status/item count) —
 * never a computed total/discount breakdown, so a webhook payload can never
 * drift out of sync with the definitive, server-side pricing engine
 * (TASK-170: "Payload de webhook nunca inclui... dados sensíveis além do
 * necessário ao evento").
 */
export const enqueueOrderWebhookEvents = onDocumentWritten(
  'organizations/{organizationId}/orders/{orderId}',
  async (event) => {
    const { organizationId, orderId } = event.params;
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!after) return; // Order deletion never produces a webhook event.

    const db = getFirestore();
    try {
      if (!before) {
        await enqueueWebhookEvent(db, {
          organizationId,
          eventType: 'order.created',
          entityId: orderId,
          sourceVersion: String(after.version ?? 1),
          data: buildOrderSummary(orderId, organizationId, after),
          now: new Date(),
        });
        return;
      }

      if (before.status !== after.status) {
        await enqueueWebhookEvent(db, {
          organizationId,
          eventType: 'order.status_changed',
          entityId: orderId,
          sourceVersion: `${after.version ?? 1}:${after.status}`,
          data: {
            orderId,
            organizationId,
            previousStatus: before.status,
            currentStatus: after.status,
            changedAt: new Date().toISOString(),
          },
          now: new Date(),
        });
      }
    } catch (error) {
      // Never blocks/retries the order write itself — a webhook-enqueue
      // failure is logged and swallowed here, same isolation guarantee
      // `recomputeSalesDailyOnOrderWrite` already documents for its own
      // side effect.
      logger.error('enqueueOrderWebhookEvents failed', {
        organizationId,
        orderId,
        error: error instanceof Error ? error.message : String(error),
      });
    }
  },
);

function buildOrderSummary(
  orderId: string,
  organizationId: string,
  order: DocumentData,
): Record<string, unknown> {
  return {
    orderId,
    organizationId,
    companyId: order.companyId ?? null,
    customerId: order.customerId ?? null,
    sellerId: order.sellerId ?? null,
    orderNumber: order.orderNumber ?? null,
    status: order.status ?? null,
    itemsCount: Array.isArray(order.items) ? order.items.length : 0,
    createdAt:
      order.createdAt?.toDate?.()?.toISOString?.() ?? new Date().toISOString(),
  };
}
