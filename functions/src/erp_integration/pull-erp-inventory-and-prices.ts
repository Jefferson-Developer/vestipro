import { logger } from 'firebase-functions/v2';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';

import { loadErpIntegrationConfig, loadErpIntegrationCredentials } from './erp-config-loader';
import { enqueueErpSyncItem } from './enqueue-erp-sync-item';
import {
  buildDefaultErpAdapterRegistry,
  type ErpAdapterRegistry,
} from './adapters/erp-adapter-registry';

export interface PullErpDataSummary {
  organizationsProcessed: number;
  recordsEnqueued: number;
  recordsDeduped: number;
  organizationsFailed: number;
}

/**
 * Scheduled producer (TASK-169) that pulls inventory/price snapshots from
 * every organization's configured ERP and enqueues one `erpSyncQueue` item
 * per returned record — the per-record queue granularity is what gives
 * partial-failure isolation here too: a single malformed record from the
 * ERP only fails its own queue item once `processErpSyncQueueItem` runs,
 * never blocks the rest of the pulled batch, and a whole organization's ERP
 * being unreachable never blocks any other organization's pull (mirrors
 * `expireStockReservationsForAllOrganizations`, TASK-092).
 */
export const pullErpInventoryAndPrices = onSchedule(
  {
    schedule: '0 * * * *',
    timeZone: 'America/Sao_Paulo',
    region: 'southamerica-east1',
  },
  async () => {
    const summary = await pullErpDataForAllOrganizations(
      getFirestore(),
      new Date(),
      buildDefaultErpAdapterRegistry(),
    );
    logger.info('pullErpInventoryAndPrices finished', summary);
  },
);

export async function pullErpDataForAllOrganizations(
  db: Firestore,
  now: Date,
  registry: ErpAdapterRegistry,
): Promise<PullErpDataSummary> {
  const organizationsSnapshot = await db.collection('organizations').get();
  const summary: PullErpDataSummary = {
    organizationsProcessed: 0,
    recordsEnqueued: 0,
    recordsDeduped: 0,
    organizationsFailed: 0,
  };

  for (const organizationDoc of organizationsSnapshot.docs) {
    const data = organizationDoc.data();
    if (data.deletedAt != null || data.status === 'inactive') continue;

    try {
      const config = await loadErpIntegrationConfig(db, organizationDoc.id);
      if (!config) continue;
      const credentials = await loadErpIntegrationCredentials(db, organizationDoc.id);
      if (!credentials) continue;
      const adapter = registry.resolve(config.adapterType);

      const pullTargets: Array<{ entityType: 'inventory' | 'price'; records: Awaited<ReturnType<typeof adapter.pullInventory>> }> = [];
      if (config.enabledEntityTypes.includes('inventory')) {
        pullTargets.push({
          entityType: 'inventory',
          records: await adapter.pullInventory(config, credentials),
        });
      }
      if (config.enabledEntityTypes.includes('price')) {
        pullTargets.push({
          entityType: 'price',
          records: await adapter.pullPrices(config, credentials),
        });
      }

      for (const target of pullTargets) {
        for (const record of target.records) {
          const result = await enqueueErpSyncItem(db, {
            organizationId: organizationDoc.id,
            direction: 'inbound',
            entityType: target.entityType,
            externalId: record.externalId,
            rawFields: record.rawFields,
            sourceVersion: record.sourceVersion,
            now,
          });
          if (result.deduped) summary.recordsDeduped += 1;
          else summary.recordsEnqueued += 1;
        }
      }
      summary.organizationsProcessed += 1;
    } catch (error) {
      summary.organizationsFailed += 1;
      logger.error('pullErpInventoryAndPrices failed for organization', {
        organizationId: organizationDoc.id,
        error: error instanceof Error ? error.message : String(error),
      });
    }
  }

  return summary;
}
