import type { DocumentData, Firestore } from 'firebase-admin/firestore';

/**
 * Shared vocabulary for the ERP integration framework (TASK-169, EPIC-22).
 *
 * `InboundErpEntityType` is deliberately narrower than `ErpEntityType`: every
 * inbound-only code path (`erpConflictPolicyFor`,
 * `ERP_MANAGEABLE_FIELDS_BY_ENTITY`, `ErpAdapter.pullInventory`/
 * `pullPrices`'s conceptual targets) is typed against it, and it has no
 * `'order'` member — so an ERP can never push data through the
 * mapping/conflict pipeline into a VestiPro Order (a compile-time guarantee,
 * not just a runtime check, matching the explicit restriction in
 * `TASK-169`: "Sincronização de entrada... nunca sobrescreve um pedido em
 * andamento no VestiPro"). `'order'` only ever appears as
 * `ErpEntityType.order`, and only ever tagged `direction: 'outbound'`
 * (`ErpAdapter.pushOrder`) — VestiPro pushes an Order out, an ERP never
 * pushes one back in.
 */
export type InboundErpEntityType = 'customer' | 'inventory' | 'price';

export type ErpEntityType = InboundErpEntityType | 'order';

export type ErpSyncDirection = 'inbound' | 'outbound';

export type ErpQueueItemStatus =
  | 'pending'
  | 'processing'
  | 'completed'
  | 'failed'
  | 'conflict';

/**
 * Mirrors `ConflictPolicy` (`lib/core/sync/domain/entities/conflict_policy.dart`,
 * TASK-110) field-for-field, including the same stable `code` strings — the
 * enum itself cannot be shared across the Dart client and this Node.js
 * Cloud Functions runtime, so this is a deliberate, documented duplication of
 * the *policy vocabulary*, not a reinterpretation of it. Any future change to
 * the Dart enum's semantics must be mirrored here by hand.
 */
export type ErpConflictPolicy =
  | 'last_write_wins'
  | 'field_merge'
  | 'manual_resolution';

export interface ErpFieldMapping {
  /** erpFieldName -> vestiproFieldName. Only fields present in the
   * entity-type's whitelist (`ERP_MANAGEABLE_FIELDS_BY_ENTITY`) may appear as
   * a value here — enforced by `validateFieldMappingConfig`. */
  [erpFieldName: string]: string;
}

export type ErpFieldMappingsByEntity = Partial<
  Record<InboundErpEntityType, ErpFieldMapping>
>;

export interface ErpIntegrationConfig {
  organizationId: string;
  adapterType: string;
  enabledEntityTypes: ErpEntityType[];
  fieldMappings: ErpFieldMappingsByEntity;
  /** Reference adapter-specific, non-secret connection details (e.g. base
   * URL/endpoint paths). Adapter-specific credentials (tokens/API keys)
   * NEVER live here — see `ErpIntegrationCredentials`/`erpCredentialsRef`. */
  connection: Record<string, unknown>;
  isActive: boolean;
}

/** Never read by any Firestore Security Rule path available to a client —
 * `firestore.rules`' `erpIntegration/credentials` document always denies
 * `read`/`write` outright; only Admin SDK code (this feature's own Cloud
 * Functions) ever touches it. */
export interface ErpIntegrationCredentials {
  organizationId: string;
  /** Opaque secret payload (e.g. `{ bearerToken: '...' }` for the reference
   * REST adapter) — never logged, never echoed back in any callable
   * response. */
  secrets: Record<string, string>;
}

export interface ErpPullRecord {
  /** The ERP's own identifier for this record — never a VestiPro id. */
  externalId: string;
  /** Raw erpFieldName -> value, straight from the ERP, before
   * `applyFieldMapping` translates it into VestiPro's vocabulary. */
  rawFields: Record<string, unknown>;
  /** Opaque version/timestamp string the ERP reports for this record, used
   * as part of the idempotency key so the exact same ERP-side revision is
   * never processed twice. */
  sourceVersion: string;
}

export interface ErpPushOrderInput {
  organizationId: string;
  orderId: string;
  externalCustomerId: string | null;
  payload: Record<string, unknown>;
}

export interface ErpPushCustomerInput {
  organizationId: string;
  customerId: string;
  payload: Record<string, unknown>;
}

export interface ErpPushResult {
  /** The ERP's own identifier assigned to (or already holding) the pushed
   * record — persisted back so future syncs can correlate by it. */
  externalId: string;
}

/**
 * Single contract every concrete ERP integration (SAP, TOTVS, Linx, a
 * generic REST endpoint, a scheduled file export, ...) implements —
 * `ErpAdapterRegistry` is the only place that decides which concrete class
 * answers for a given `adapterType`; no queue/processing code ever
 * `instanceof`s or otherwise special-cases a concrete adapter.
 */
export interface ErpAdapter {
  readonly adapterType: string;

  pullInventory(
    config: ErpIntegrationConfig,
    credentials: ErpIntegrationCredentials,
  ): Promise<ErpPullRecord[]>;

  pullPrices(
    config: ErpIntegrationConfig,
    credentials: ErpIntegrationCredentials,
  ): Promise<ErpPullRecord[]>;

  pushOrder(
    config: ErpIntegrationConfig,
    credentials: ErpIntegrationCredentials,
    input: ErpPushOrderInput,
  ): Promise<ErpPushResult>;

  pushCustomer(
    config: ErpIntegrationConfig,
    credentials: ErpIntegrationCredentials,
    input: ErpPushCustomerInput,
  ): Promise<ErpPushResult>;
}

export interface ErpSyncQueueItemDoc extends DocumentData {
  organizationId: string;
  direction: ErpSyncDirection;
  entityType: ErpEntityType;
  externalId: string;
  rawFields: Record<string, unknown>;
  sourceVersion: string;
  idempotencyKey: string;
  status: ErpQueueItemStatus;
  attempts: number;
  lastError: string | null;
  nextRetryAt: unknown;
  createdAt: unknown;
  processedAt: unknown | null;
}

export interface ErpProcessItemDeps {
  db: Firestore;
  now: Date;
}
