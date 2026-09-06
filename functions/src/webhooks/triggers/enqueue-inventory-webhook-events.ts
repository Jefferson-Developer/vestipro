import { logger } from 'firebase-functions/v2';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { getFirestore } from 'firebase-admin/firestore';

import { asBalanceSnapshot, sellableQuantity } from '../../inventory/stock-alert-shared';
import { enqueueWebhookEvent } from '../enqueue-webhook-event';

/**
 * Produces the `inventory.updated` webhook event (TASK-170) from the exact
 * same `inventory` balance-write shape `syncStockAlerts` (TASK-090) already
 * parses (`asBalanceSnapshot`) — reused here, not reimplemented, so both
 * features agree on what a balance document looks like.
 *
 * Fires only when the *sellable* quantity actually changed — a write that
 * only touches metadata (e.g. `lastSource`) with the same
 * physical/reserved/blocked quantities never produces a webhook event, same
 * "meaningful change only" guard `syncStockAlertsForBalanceChange` already
 * applies via `resolveTransitionType`.
 */
export const enqueueInventoryWebhookEvents = onDocumentWritten(
  'organizations/{organizationId}/inventory/{inventoryId}',
  async (event) => {
    const { organizationId, inventoryId } = event.params;
    const before = asBalanceSnapshot(event.data?.before.data());
    const after = asBalanceSnapshot(event.data?.after.data());
    if (!after) return; // Deletion, or a shape too malformed to parse.

    const previousQuantity = sellableQuantity(before);
    const currentQuantity = sellableQuantity(after);
    if (previousQuantity === currentQuantity) return;

    const db = getFirestore();
    try {
      await enqueueWebhookEvent(db, {
        organizationId,
        eventType: 'inventory.updated',
        entityId: inventoryId,
        sourceVersion: String(after.version),
        data: {
          inventoryId,
          organizationId,
          productId: after.productId,
          variantId: after.variantId,
          warehouseId: after.warehouseId,
          sellableQuantity: currentQuantity,
          updatedAt: after.updatedAt.toDate().toISOString(),
        },
        now: new Date(),
      });
    } catch (error) {
      logger.error('enqueueInventoryWebhookEvents failed', {
        organizationId,
        inventoryId,
        error: error instanceof Error ? error.message : String(error),
      });
    }
  },
);
