import { logger } from 'firebase-functions/v2';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import {
  FieldValue,
  Timestamp,
  getFirestore,
  type DocumentReference,
  type Firestore,
} from 'firebase-admin/firestore';

import {
  applyFieldMapping,
  erpConflictsCollection,
  erpProcessedEventsCollection,
  erpSyncLogsCollection,
  erpSyncQueueCollection,
  erpSyncedRecordsCollection,
  erpConflictPolicyFor,
  isInboundErpEntityType,
  nextRetryDelayMinutes,
  MAX_SYNC_ATTEMPTS,
} from './erp-integration-shared';
import {
  loadErpIntegrationConfig,
  loadErpIntegrationCredentials,
} from './erp-config-loader';
import { computeErpFieldMerge } from './field-merge';
import { buildDefaultErpAdapterRegistry } from './adapters/erp-adapter-registry';
import type { ErpAdapterRegistry } from './adapters/erp-adapter-registry';
import type { ErpSyncQueueItemDoc } from './types';

/**
 * Claims a `pending` queue item so it is never processed twice concurrently
 * (the trigger firing again on a retried Cloud Function invocation, and
 * `retryFailedErpSyncItems` calling this same core for a `failed` item, both
 * go through here) — returns `null` when there is nothing to claim (already
 * claimed, or a status this claim call was never meant to pick up).
 */
export async function claimErpSyncQueueItem(
  db: Firestore,
  organizationId: string,
  itemId: string,
  acceptedStatuses: readonly string[],
): Promise<ErpSyncQueueItemDoc | null> {
  const itemRef = erpSyncQueueCollection(db, organizationId).doc(itemId);
  return db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(itemRef);
    if (!snapshot.exists) return null;
    const data = snapshot.data() as ErpSyncQueueItemDoc;
    if (!acceptedStatuses.includes(data.status)) return null;
    transaction.update(itemRef, { status: 'processing' });
    return { ...data, status: 'processing' };
  });
}

interface OutcomeLog {
  status: 'success' | 'failed' | 'conflict' | 'skipped_duplicate' | 'skipped_not_found';
  errorMessage: string | null;
}

/**
 * The framework's actual sync core (TASK-169) — shared, unmodified, by the
 * `onDocumentCreated` trigger below and `retryFailedErpSyncItems`'s manual
 * re-invocation, so there is exactly one place that decides how a queue item
 * is applied. Never throws: every failure path is caught internally and
 * reflected in the item's own `status`/`lastError` plus a sync-log entry,
 * so one bad item can never abort whatever loop is iterating a batch
 * (TASK-169: "falha em um lote não impede o processamento dos demais").
 */
export async function processClaimedErpSyncQueueItem(
  db: Firestore,
  organizationId: string,
  itemId: string,
  item: ErpSyncQueueItemDoc,
  now: Date,
  registry: ErpAdapterRegistry = buildDefaultErpAdapterRegistry(),
): Promise<void> {
  const itemRef = erpSyncQueueCollection(db, organizationId).doc(itemId);
  let outcome: OutcomeLog;

  try {
    outcome = await runSync(db, organizationId, itemRef, item, now, registry);
  } catch (error) {
    const attempts = (item.attempts ?? 0) + 1;
    const message =
      error instanceof Error ? error.message : 'Erro inesperado na sincronização.';
    const willRetry = attempts < MAX_SYNC_ATTEMPTS;
    await itemRef.update({
      status: 'failed',
      attempts,
      lastError: message,
      nextRetryAt: willRetry
        ? Timestamp.fromDate(
            new Date(now.getTime() + nextRetryDelayMinutes(attempts) * 60_000),
          )
        : null,
      processedAt: Timestamp.fromDate(now),
    });
    outcome = { status: 'failed', errorMessage: message };
  }

  await erpSyncLogsCollection(db, organizationId).add({
    organizationId,
    itemId,
    direction: item.direction,
    entityType: item.entityType,
    externalId: item.externalId,
    status: outcome.status,
    errorMessage: outcome.errorMessage,
    attempts: item.attempts ?? 0,
    createdAt: Timestamp.fromDate(now),
  });

  logger.info('processErpSyncQueueItem finished', {
    organizationId,
    itemId,
    entityType: item.entityType,
    direction: item.direction,
    status: outcome.status,
  });
}

async function runSync(
  db: Firestore,
  organizationId: string,
  itemRef: DocumentReference,
  item: ErpSyncQueueItemDoc,
  now: Date,
  registry: ErpAdapterRegistry,
): Promise<OutcomeLog> {
  const processedRef = erpProcessedEventsCollection(db, organizationId).doc(
    item.idempotencyKey,
  );
  const alreadyProcessed = await processedRef.get();
  if (alreadyProcessed.exists) {
    await itemRef.update({ status: 'completed', processedAt: Timestamp.fromDate(now) });
    return { status: 'skipped_duplicate', errorMessage: null };
  }

  const config = await loadErpIntegrationConfig(db, organizationId);
  if (!config) {
    throw new Error(
      'Integração de ERP não configurada ou desativada para esta organização.',
    );
  }
  const credentials = await loadErpIntegrationCredentials(db, organizationId);
  if (!credentials) {
    throw new Error('Credenciais de integração de ERP não configuradas.');
  }
  // Adapter is resolved (and, for outbound items, actually called) below —
  // kept even for inbound items that don't call it in v1 (the pull-driven
  // producer already called the adapter before enqueuing) so a misconfigured
  // `adapterType` is still caught deterministically at process time too.
  const adapter = registry.resolve(config.adapterType);

  if (item.direction === 'outbound') {
    if (item.entityType === 'order') {
      const result = await adapter.pushOrder(config, credentials, {
        organizationId,
        orderId: item.externalId,
        externalCustomerId:
          typeof item.rawFields.externalCustomerId === 'string'
            ? item.rawFields.externalCustomerId
            : null,
        payload: item.rawFields,
      });
      await markCompleted(itemRef, processedRef, now, {
        entityType: item.entityType,
        externalId: result.externalId,
      });
      return { status: 'success', errorMessage: null };
    }
    if (item.entityType === 'customer') {
      const result = await adapter.pushCustomer(config, credentials, {
        organizationId,
        customerId: item.externalId,
        payload: item.rawFields,
      });
      await markCompleted(itemRef, processedRef, now, {
        entityType: item.entityType,
        externalId: result.externalId,
      });
      return { status: 'success', errorMessage: null };
    }
    throw new Error(
      `Tipo de entidade "${item.entityType}" não suporta envio (outbound) ao ERP.`,
    );
  }

  if (!isInboundErpEntityType(item.entityType)) {
    throw new Error(
      `Tipo de entidade "${item.entityType}" não é permitido para sincronização de entrada.`,
    );
  }

  const mapping = config.fieldMappings[item.entityType] ?? {};
  const mappedFields = applyFieldMapping(mapping, item.rawFields);

  if (item.entityType === 'customer') {
    return applyInboundCustomer(db, organizationId, itemRef, processedRef, item, mappedFields, now);
  }

  // 'inventory'/'price': land only in the informational staging collection
  // (`erpSyncedRecords`) — never in the real `inventory`/pricing schemas,
  // which stay owned by TASK-089/090's stock-reservation engine and the
  // server-side pricing engine respectively (see
  // `ERP_MANAGEABLE_FIELDS_BY_ENTITY`'s doc comment for why). A concrete
  // adapter that resolves ERP SKU/warehouse codes to real
  // `variantId`/`warehouseId` is expected to consume this staged data in a
  // dedicated follow-up task, never here.
  await erpSyncedRecordsCollection(db, organizationId)
    .doc(`${item.entityType}_${item.externalId}`)
    .set(
      {
        organizationId,
        entityType: item.entityType,
        externalId: item.externalId,
        mappedFields,
        sourceVersion: item.sourceVersion,
        updatedAt: Timestamp.fromDate(now),
      },
      { merge: true },
    );
  await markCompleted(itemRef, processedRef, now);
  return { status: 'success', errorMessage: null };
}

async function markCompleted(
  itemRef: DocumentReference,
  processedRef: DocumentReference,
  now: Date,
  meta?: Record<string, unknown>,
): Promise<void> {
  await processedRef.set({ processedAt: Timestamp.fromDate(now), ...(meta ?? {}) });
  await itemRef.update({ status: 'completed', processedAt: Timestamp.fromDate(now) });
}

async function applyInboundCustomer(
  db: Firestore,
  organizationId: string,
  itemRef: DocumentReference,
  processedRef: DocumentReference,
  item: ErpSyncQueueItemDoc,
  mappedFields: Record<string, unknown>,
  now: Date,
): Promise<OutcomeLog> {
  const documentValue = mappedFields.document;
  if (typeof documentValue !== 'string' || documentValue.trim().length === 0) {
    throw new Error(
      'ERP não enviou (ou não mapeou) o campo "document", obrigatório para conciliar o cliente.',
    );
  }

  const organizationRef = db.collection('organizations').doc(organizationId);
  const customersSnapshot = await organizationRef
    .collection('customers')
    .where('document', '==', documentValue)
    .limit(1)
    .get();
  if (customersSnapshot.empty) {
    // Deliberately not auto-created: bulk customer creation is TASK-167's
    // own, dedicated, dedup-aware flow — this framework only reconciles an
    // ERP update against a customer that already exists in VestiPro.
    await itemRef.update({ status: 'completed', processedAt: Timestamp.fromDate(now) });
    return {
      status: 'skipped_not_found',
      errorMessage: `Nenhum cliente com document="${documentValue}" encontrado.`,
    };
  }

  const customerSnapshot = customersSnapshot.docs[0];
  const customerRef = customerSnapshot.ref;
  const customerData = customerSnapshot.data();

  const baselineRef = erpSyncedRecordsCollection(db, organizationId).doc(
    `customer_${customerSnapshot.id}`,
  );
  const baselineSnapshot = await baselineRef.get();
  const baseline = baselineSnapshot.data();

  const allowedKeys = Object.keys(mappedFields);
  const local: Record<string, unknown> = {};
  for (const key of allowedKeys) local[key] = customerData[key] ?? null;
  // No prior baseline: this is the first sync ever for this customer, so
  // there is nothing to compare against yet — the ERP's current values are
  // taken as the agreed starting point, guaranteeing the very first sync
  // never spuriously conflicts.
  const base: Record<string, unknown> = (baseline?.mappedFields as
    | Record<string, unknown>
    | undefined) ?? local;

  const merge = computeErpFieldMerge({ base, local, remote: mappedFields });

  if (merge.conflictingFields.size > 0) {
    await erpConflictsCollection(db, organizationId).add({
      organizationId,
      entityType: 'customer',
      externalId: item.externalId,
      customerId: customerSnapshot.id,
      conflictingFields: Array.from(merge.conflictingFields),
      localValues: local,
      remoteValues: mappedFields,
      policy: erpConflictPolicyFor('customer'),
      createdAt: Timestamp.fromDate(now),
      resolvedAt: null,
    });
    await itemRef.update({ status: 'conflict', processedAt: Timestamp.fromDate(now) });
    return {
      status: 'conflict',
      errorMessage: `Campos em conflito: ${Array.from(merge.conflictingFields).join(', ')}.`,
    };
  }

  await customerRef.set(
    {
      ...merge.mergedData,
      updatedAt: Timestamp.fromDate(now),
      updatedBy: 'erp-sync',
      version: FieldValue.increment(1),
    },
    { merge: true },
  );
  await baselineRef.set(
    {
      organizationId,
      entityType: 'customer',
      externalId: item.externalId,
      customerId: customerSnapshot.id,
      mappedFields: merge.mergedData,
      sourceVersion: item.sourceVersion,
      updatedAt: Timestamp.fromDate(now),
    },
    { merge: true },
  );
  await markCompleted(itemRef, processedRef, now, {
    entityType: 'customer',
    externalId: item.externalId,
  });
  return { status: 'success', errorMessage: null };
}

/**
 * Fires once per `erpSyncQueue` document creation — `enqueueErpSyncItem` is
 * the only code that ever creates one, always with `status: 'pending'`, so
 * this trigger only ever needs to claim `'pending'`. Every item is its own
 * document/invocation: one item throwing never touches any other item's
 * document, which is what actually gives TASK-169's "falha parcial não
 * compromete o lote" guarantee — there is no shared batch/transaction across
 * items to roll back.
 */
export const processErpSyncQueueItem = onDocumentCreated(
  'organizations/{organizationId}/erpSyncQueue/{itemId}',
  async (event) => {
    const { organizationId, itemId } = event.params;
    const db = getFirestore();
    const claimed = await claimErpSyncQueueItem(db, organizationId, itemId, [
      'pending',
    ]);
    if (!claimed) return;
    await processClaimedErpSyncQueueItem(
      db,
      organizationId,
      itemId,
      claimed,
      new Date(),
    );
  },
);
