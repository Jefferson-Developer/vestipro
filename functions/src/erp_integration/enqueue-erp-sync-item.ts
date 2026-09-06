import { Timestamp, type Firestore } from 'firebase-admin/firestore';

import {
  computeIdempotencyKey,
  erpSyncQueueCollection,
} from './erp-integration-shared';
import type { ErpEntityType, ErpSyncDirection } from './types';

export interface EnqueueErpSyncItemParams {
  organizationId: string;
  direction: ErpSyncDirection;
  entityType: ErpEntityType;
  externalId: string;
  rawFields: Record<string, unknown>;
  sourceVersion: string;
  now: Date;
}

export interface EnqueueErpSyncItemResult {
  itemId: string;
  /** `true` when an equivalent item (same idempotency key) was already
   * queued/processing/completed and this call was a no-op — the caller
   * (`pullErpInventoryAndPrices`, a future order/customer push trigger, a
   * redelivered webhook, ...) never needs its own dedupe logic. */
  deduped: boolean;
}

/**
 * The single entry point that ever creates an `erpSyncQueue` document
 * (TASK-169) — computes the idempotency key once, here, so every producer
 * (the scheduled inventory/price pull, a future outbound order/customer
 * push) shares the exact same dedupe guarantee instead of reimplementing it.
 *
 * Dedupe is checked against both the queue itself (an item still
 * pending/processing/completed for the same key is never duplicated) and,
 * once `processErpSyncQueueItem` runs, that item is what marks the durable
 * `erpProcessedEvents` ledger — so a queue item that failed/conflicted can
 * still be safely re-enqueued (its key was never marked processed), while a
 * queue item that already completed never is.
 */
export async function enqueueErpSyncItem(
  db: Firestore,
  params: EnqueueErpSyncItemParams,
): Promise<EnqueueErpSyncItemResult> {
  const idempotencyKey = computeIdempotencyKey({
    organizationId: params.organizationId,
    direction: params.direction,
    entityType: params.entityType,
    externalId: params.externalId,
    sourceVersion: params.sourceVersion,
  });

  const queueCollection = erpSyncQueueCollection(db, params.organizationId);
  const existing = await queueCollection
    .where('idempotencyKey', '==', idempotencyKey)
    .where('status', 'in', ['pending', 'processing', 'completed'])
    .limit(1)
    .get();
  if (!existing.empty) {
    return { itemId: existing.docs[0].id, deduped: true };
  }

  const itemRef = queueCollection.doc();
  await itemRef.set({
    organizationId: params.organizationId,
    direction: params.direction,
    entityType: params.entityType,
    externalId: params.externalId,
    rawFields: params.rawFields,
    sourceVersion: params.sourceVersion,
    idempotencyKey,
    status: 'pending',
    attempts: 0,
    lastError: null,
    nextRetryAt: null,
    createdAt: Timestamp.fromDate(params.now),
    processedAt: null,
  });
  return { itemId: itemRef.id, deduped: false };
}
