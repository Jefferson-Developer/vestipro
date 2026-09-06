import { logger } from 'firebase-functions/v2';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { Timestamp, getFirestore, type Firestore } from 'firebase-admin/firestore';

import { erpSyncQueueCollection, MAX_SYNC_ATTEMPTS } from './erp-integration-shared';
import {
  claimErpSyncQueueItem,
  processClaimedErpSyncQueueItem,
} from './process-erp-sync-queue-item';
import type { ErpSyncQueueItemDoc } from './types';

export interface RetryErpSyncSummary {
  organizationsProcessed: number;
  itemsRetried: number;
}

/**
 * Reprocesses `failed` queue items whose backoff window elapsed and whose
 * `attempts` is still under `MAX_SYNC_ATTEMPTS` (TASK-169) — deliberately
 * calls `processClaimedErpSyncQueueItem` directly instead of recreating the
 * queue document: recreating it would duplicate `erpSyncLogs`/queue history
 * and, since `processErpSyncQueueItem` only triggers on document *creation*,
 * an in-place status update back to `pending` would never re-fire it anyway.
 * A queue item stuck at `attempts >= MAX_SYNC_ATTEMPTS` is left `failed`
 * forever for manual intervention (TASK-169: "fica registrado para nova
 * tentativa/intervenção manual") — `'conflict'` items are never retried
 * here at all, since a conflict always requires a human decision, never an
 * automatic one.
 */
export const retryFailedErpSyncItems = onSchedule(
  {
    schedule: '*/15 * * * *',
    timeZone: 'America/Sao_Paulo',
    region: 'southamerica-east1',
  },
  async () => {
    const summary = await retryFailedErpSyncItemsForAllOrganizations(
      getFirestore(),
      new Date(),
    );
    logger.info('retryFailedErpSyncItems finished', summary);
  },
);

export async function retryFailedErpSyncItemsForAllOrganizations(
  db: Firestore,
  now: Date,
): Promise<RetryErpSyncSummary> {
  const organizationsSnapshot = await db.collection('organizations').get();
  let organizationsProcessed = 0;
  let itemsRetried = 0;

  for (const organizationDoc of organizationsSnapshot.docs) {
    const data = organizationDoc.data();
    if (data.deletedAt != null || data.status === 'inactive') continue;

    const dueSnapshot = await erpSyncQueueCollection(db, organizationDoc.id)
      .where('status', '==', 'failed')
      .where('attempts', '<', MAX_SYNC_ATTEMPTS)
      .where('nextRetryAt', '<=', Timestamp.fromDate(now))
      .get();

    for (const itemDoc of dueSnapshot.docs) {
      const claimed = await claimErpSyncQueueItem(
        db,
        organizationDoc.id,
        itemDoc.id,
        ['failed'],
      );
      if (!claimed) continue;
      await processClaimedErpSyncQueueItem(
        db,
        organizationDoc.id,
        itemDoc.id,
        claimed as ErpSyncQueueItemDoc,
        now,
      );
      itemsRetried += 1;
    }
    organizationsProcessed += 1;
  }

  return { organizationsProcessed, itemsRetried };
}
