import { createHash } from 'node:crypto';

import { HttpsError } from 'firebase-functions/v2/https';
import type { DocumentReference, Firestore } from 'firebase-admin/firestore';

import type {
  ErpConflictPolicy,
  ErpFieldMapping,
  ErpFieldMappingsByEntity,
  ErpPullRecord,
  InboundErpEntityType,
} from './types';

/**
 * Shared by every ERP-integration Cloud Function (TASK-169, EPIC-22):
 * `saveErpIntegrationConfig`, `saveErpIntegrationCredentials`,
 * `processErpSyncQueueItem`, `pullErpInventoryAndPrices`,
 * `retryFailedErpSyncItems` — same "RBAC/vocabulary/validation defined
 * exactly once" rationale `customer-import-shared.ts` (TASK-167)/
 * `product-import-shared.ts` (TASK-168) already document.
 */

/** Mirrors `Capability.erpIntegrationManage`
 * (`lib/core/permissions/capability.dart`) — granted only to OWNER/ADMIN
 * (`RolePermissionMatrix`'s full/near-full sets), same restrictive scope as
 * `PRODUCT_IMPORT_ROLES`: configuring which ERP an organization talks to,
 * its credentials and its field mapping is an infrastructure decision, never
 * delegated to SALES_MANAGER/SALES_REP/SALES_ASSISTANT/FINANCE. */
export const ERP_INTEGRATION_ROLES: ReadonlySet<string> = new Set<string>([
  'OWNER',
  'ADMIN',
]);

export function assertCanManageErpIntegration(roleName: string): void {
  if (!ERP_INTEGRATION_ROLES.has(roleName)) {
    throw new HttpsError(
      'permission-denied',
      'Seu perfil não pode configurar integrações de ERP.',
    );
  }
}

/**
 * Which VestiPro fields an ERP is ever allowed to claim ownership of, per
 * entity type — the "no-code mapping" (`TASK-169`'s "Modelar mapeamento de
 * campos configurável por organização") is only ever a *restriction* within
 * this whitelist, never an arbitrary key an admin could type in to reach an
 * unrelated/sensitive field (`organizationId`, `version`, pricing/discount
 * fields, anything Order-shaped). `validateFieldMappingConfig` is the single
 * enforcement point.
 *
 * `customer`'s whitelist deliberately only covers ERP-owned master-data
 * fields (document/legalName/tradeName/stateRegistration/address*) — the
 * exact same field vocabulary `CUSTOMER_IMPORT_FIELD_CODES`
 * (`customer-import-shared.ts`, TASK-167) already defines for these
 * columns, minus the CRM-owned fields (`fullName`, `primaryEmail`,
 * `primaryPhone`, `classification`, `potential`, `segment`,
 * `originChannel`) a seller/gestor manages in-app, never an ERP.
 *
 * `inventory`/`price` only ever map into informational, non-authoritative
 * fields (`erpQuantityOnHand`, `erpUnitCost`) — never the real
 * `quantityOnHand`/`reservedQuantity` (`inventory` collection, owned by the
 * stock-reservation engine, TASK-089/090) nor any `PriceList` field
 * (pricing stays server-side/definitive per the architecture rules; an ERP
 * feed is only ever a reference input for a future, dedicated pricing-import
 * task to consume deliberately, never applied automatically here).
 */
export const ERP_MANAGEABLE_FIELDS_BY_ENTITY: Readonly<
  Record<InboundErpEntityType, ReadonlySet<string>>
> = {
  customer: new Set<string>([
    'document',
    'legalName',
    'tradeName',
    'stateRegistration',
    'addressStreet',
    'addressNumber',
    'addressComplement',
    'addressDistrict',
    'addressCity',
    'addressState',
    'addressZipCode',
  ]),
  inventory: new Set<string>(['erpQuantityOnHand']),
  price: new Set<string>(['erpUnitCost']),
};

/**
 * Mirrors `ConflictPolicyCatalog.policyFor`
 * (`lib/core/sync/domain/conflict_policy_catalog.dart`, TASK-110) for the
 * ERP-integration entity types (`TASK-169`: "aplicar a mesma política de
 * resolução de conflito já definida no motor de sincronização existente").
 *
 * - `customer` -> `field_merge`, the exact same policy/reasoning the Dart
 *   catalog already assigns to `OutboxEntityType.customer`: ERP master data
 *   and an in-app edit are expected to touch disjoint fields most of the
 *   time, so a field-by-field merge is safe, downgrading to
 *   `manual_resolution` only when the very same field changed on both sides
 *   since the last successful sync (see `decideCustomerConflict`).
 * - `inventory`/`price` -> `last_write_wins`: these only ever write into the
 *   informational fields above, which nothing else in the app ever writes
 *   (see `ERP_MANAGEABLE_FIELDS_BY_ENTITY`'s doc comment) — there is no
 *   second writer to conflict with, so the most recent ERP pull is always
 *   safe to keep, same "no financial/critical implication" reasoning the
 *   Dart catalog uses for `OutboxEntityType.crmActivity`.
 */
export function erpConflictPolicyFor(
  entityType: InboundErpEntityType,
): ErpConflictPolicy {
  switch (entityType) {
    case 'customer':
      return 'field_merge';
    case 'inventory':
      return 'last_write_wins';
    case 'price':
      return 'last_write_wins';
  }
}

export const MAX_SYNC_ATTEMPTS = 5;

/** Minutes to wait before retrying a failed queue item, indexed by
 * `attempts - 1` (attempts is 1-based after the first failure) — capped at
 * the last entry for any attempt beyond this table's length. */
export const RETRY_BACKOFF_MINUTES: readonly number[] = [5, 15, 60, 240, 1440];

export function nextRetryDelayMinutes(attempts: number): number {
  const index = Math.min(attempts, RETRY_BACKOFF_MINUTES.length) - 1;
  return RETRY_BACKOFF_MINUTES[Math.max(index, 0)];
}

/** Validates a raw field-mapping payload sent to `saveErpIntegrationConfig`
 * — every erpFieldName must be a non-empty string and every mapped
 * vestiproFieldName must belong to `ERP_MANAGEABLE_FIELDS_BY_ENTITY` for that
 * entity type, so a forged/stale client mapping can never reach a field
 * outside the whitelist. Throws `HttpsError('invalid-argument', ...)`
 * otherwise. */
export function validateFieldMappingConfig(
  raw: unknown,
): ErpFieldMappingsByEntity {
  if (raw === null || raw === undefined) return {};
  if (typeof raw !== 'object' || Array.isArray(raw)) {
    throw new HttpsError(
      'invalid-argument',
      'fieldMappings deve ser um objeto por tipo de entidade.',
    );
  }

  const result: ErpFieldMappingsByEntity = {};
  for (const [entityType, mapping] of Object.entries(
    raw as Record<string, unknown>,
  )) {
    if (!isInboundErpEntityType(entityType)) {
      throw new HttpsError(
        'invalid-argument',
        `Tipo de entidade desconhecido em fieldMappings: ${entityType}.`,
      );
    }
    if (
      mapping === null ||
      typeof mapping !== 'object' ||
      Array.isArray(mapping)
    ) {
      throw new HttpsError(
        'invalid-argument',
        `Mapeamento de campos inválido para "${entityType}".`,
      );
    }

    const allowedFields = ERP_MANAGEABLE_FIELDS_BY_ENTITY[entityType];
    const validatedMapping: ErpFieldMapping = {};
    for (const [erpField, vestiproField] of Object.entries(
      mapping as Record<string, unknown>,
    )) {
      if (typeof erpField !== 'string' || erpField.trim().length === 0) {
        throw new HttpsError(
          'invalid-argument',
          `Nome de campo do ERP inválido para "${entityType}".`,
        );
      }
      if (
        typeof vestiproField !== 'string' ||
        !allowedFields.has(vestiproField)
      ) {
        throw new HttpsError(
          'invalid-argument',
          `Campo "${vestiproField}" não é permitido para o tipo de entidade "${entityType}".`,
        );
      }
      validatedMapping[erpField.trim()] = vestiproField;
    }
    result[entityType] = validatedMapping;
  }
  return result;
}

export function isInboundErpEntityType(
  value: string,
): value is InboundErpEntityType {
  return value === 'customer' || value === 'inventory' || value === 'price';
}

/** Translates a raw ERP record into VestiPro's own field vocabulary using an
 * organization's configured mapping — an ERP field absent from the mapping
 * is silently ignored (never guessed), and a mapped ERP field absent from
 * the raw record is skipped (never written as `undefined`/`null` by
 * surprise). */
export function applyFieldMapping(
  mapping: ErpFieldMapping,
  rawFields: Record<string, unknown>,
): Record<string, unknown> {
  const mapped: Record<string, unknown> = {};
  for (const [erpField, vestiproField] of Object.entries(mapping)) {
    if (Object.prototype.hasOwnProperty.call(rawFields, erpField)) {
      mapped[vestiproField] = rawFields[erpField];
    }
  }
  return mapped;
}

export interface IdempotencyKeyInput {
  organizationId: string;
  direction: string;
  entityType: string;
  externalId: string;
  sourceVersion: string;
}

/** Deterministic idempotency key (TASK-169: "reprocessar o mesmo evento não
 * duplica pedido nem corrompe estoque") — the exact same
 * organization/direction/entityType/externalId/sourceVersion tuple always
 * hashes to the exact same key, so enqueuing (or reprocessing) the same ERP
 * event twice is always detected, regardless of how many times the pull ran
 * or how many times a webhook/retry redelivered it. */
export function computeIdempotencyKey(input: IdempotencyKeyInput): string {
  const canonical = [
    input.organizationId,
    input.direction,
    input.entityType,
    input.externalId,
    input.sourceVersion,
  ].join('|');
  return createHash('sha256').update(canonical).digest('hex');
}

export function idempotencyKeyForPullRecord(
  organizationId: string,
  entityType: InboundErpEntityType,
  record: ErpPullRecord,
): string {
  return computeIdempotencyKey({
    organizationId,
    direction: 'inbound',
    entityType,
    externalId: record.externalId,
    sourceVersion: record.sourceVersion,
  });
}

// ---------------------------------------------------------------------------
// Firestore path helpers — the single place every ERP-integration Cloud
// Function builds a path from, so a path can never accidentally drift
// outside `organizations/{organizationId}/...` and leak across tenants.
// ---------------------------------------------------------------------------

export function erpIntegrationConfigRef(
  db: Firestore,
  organizationId: string,
): DocumentReference {
  return db
    .collection('organizations')
    .doc(organizationId)
    .collection('erpIntegration')
    .doc('config');
}

export function erpIntegrationCredentialsRef(
  db: Firestore,
  organizationId: string,
): DocumentReference {
  return db
    .collection('organizations')
    .doc(organizationId)
    .collection('erpIntegration')
    .doc('credentials');
}

export function erpSyncQueueCollection(db: Firestore, organizationId: string) {
  return db
    .collection('organizations')
    .doc(organizationId)
    .collection('erpSyncQueue');
}

export function erpSyncLogsCollection(db: Firestore, organizationId: string) {
  return db
    .collection('organizations')
    .doc(organizationId)
    .collection('erpSyncLogs');
}

export function erpConflictsCollection(db: Firestore, organizationId: string) {
  return db
    .collection('organizations')
    .doc(organizationId)
    .collection('erpConflicts');
}

export function erpSyncedRecordsCollection(
  db: Firestore,
  organizationId: string,
) {
  return db
    .collection('organizations')
    .doc(organizationId)
    .collection('erpSyncedRecords');
}

export function erpProcessedEventsCollection(
  db: Firestore,
  organizationId: string,
) {
  return db
    .collection('organizations')
    .doc(organizationId)
    .collection('erpProcessedEvents');
}
