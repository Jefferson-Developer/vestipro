import 'package:drift/drift.dart';

/// Local queue of offline write operations pending synchronization
/// (TASK-108, EPIC-14 — Outbox Pattern, seção 5.4 de `tasks.md`).
///
/// Every operation performed while offline that must eventually reach the
/// backend (creating/updating an `Order`, logging a `crmActivity`, ...)
/// writes exactly one row here, in the *same* Drift transaction as the
/// local mutation itself (see `AppDatabase.enqueueOutboxOperation` docs) —
/// this table, not the entity's own `syncStatus` column, is what the future
/// sync engine (TASK-109) and the Central de Sincronização (TASK-112) read
/// to know what still needs to reach Firestore/Functions and in what order.
///
/// [id] doubles as the operation's `clientOperationId`: it is generated
/// client-side once, when the operation is first attempted, and callers
/// must reuse that exact same value on every retry of that same logical
/// operation (app crash/restart mid-write, connectivity flapping, ...) so
/// `enqueue` stays idempotent — a second `enqueue` call with an [id] that
/// already exists here is a no-op, never a duplicate row. TASK-109's
/// backend/Functions reuse this same value to deduplicate a replayed
/// operation server-side.
///
/// [entityType]/[operationType]/[status] are stored as stable string codes
/// (never an enum index) so a future reordering of
/// `OutboxEntityType`/`OutboxOperationType`/`OutboxStatus` can never
/// silently change what an already-persisted row means — same convention
/// as [OfflinePackageLoadStatusTable]'s `entityKind`. [payload] is the
/// operation's DTO, JSON-encoded, so it can be re-executed against the
/// backend without depending on any other local table still holding the
/// data (that row could have moved on / been edited again by the time sync
/// actually runs).
///
/// [sequenceNumber] is the *local* creation order — strictly increasing
/// across every row ever enqueued in this table, regardless of
/// `entityId`/`entityType` — and is what lets the sync engine process every
/// operation for the same [entityId] in the order it actually happened
/// locally (e.g. never apply an `update` before the `create` it depends
/// on), without relying on wall-clock timestamps that can collide or skew.
@TableIndex(
  name: 'idx_outbox_scope_status',
  columns: {#organizationId, #status},
)
@TableIndex(
  name: 'idx_outbox_entity',
  columns: {#organizationId, #entityType, #entityId, #sequenceNumber},
)
class OutboxTable extends Table {
  @override
  String get tableName => 'outbox';

  TextColumn get id => text()();
  TextColumn get organizationId => text()();
  TextColumn get companyId => text().nullable()();

  /// Stable identifier of an `OutboxEntityType` value (e.g. `'order'`).
  TextColumn get entityType => text()();

  /// Id of the local/domain entity this operation applies to (e.g. the
  /// `Order.id` for an order draft submission).
  TextColumn get entityId => text()();

  /// Stable identifier of an `OutboxOperationType` value (`'create'`,
  /// `'update'` or `'delete'`).
  TextColumn get operationType => text()();

  /// JSON-encoded payload of the operation's DTO — re-executable on its
  /// own, without depending on the entity's current local row.
  TextColumn get payload => text()();

  /// Stable identifier of an `OutboxStatus` value: `'pending'`, `'syncing'`,
  /// `'synced'`, `'failed'` or `'conflict'`.
  TextColumn get status => text().withDefault(const Constant('pending'))();

  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  TextColumn get createdBy => text()();

  IntColumn get sequenceNumber => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
