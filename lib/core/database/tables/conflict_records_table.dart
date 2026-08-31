import 'package:drift/drift.dart';

/// Local persistence for [ConflictRecord] (TASK-110, EPIC-14 — seção 5.5 de
/// `tasks.md`): a conflict [ConflictResolutionService] could not resolve
/// automatically, kept until a human resolves it (TASK-111).
///
/// A row here always corresponds 1:1 to the exact `outboxOperationId` it
/// blocks — `ConflictResolutionService` moves that Outbox row to
/// `OutboxStatus.conflict` in the same call that inserts this row, so both
/// are always consistent with each other (see
/// `AppDatabase.enqueueOutboxOperation`'s docs for the equivalent
/// same-transaction guarantee on the Outbox side).
///
/// [entityType]/[policy]/[status] are stored as stable string codes (never
/// an enum index), same convention as [OutboxTable].
/// [localSnapshot]/[remoteSnapshot] are the full entity snapshot on each
/// side, JSON-encoded, so TASK-111's comparison screen can render the
/// complete picture, not only [conflictingFields].
@TableIndex(
  name: 'idx_conflict_records_scope_status',
  columns: {#organizationId, #status},
)
class ConflictRecordsTable extends Table {
  @override
  String get tableName => 'conflict_records';

  TextColumn get id => text()();
  TextColumn get organizationId => text()();
  TextColumn get companyId => text().nullable()();

  /// Stable identifier of an `OutboxEntityType` value.
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();

  /// The `OutboxOperation.clientOperationId` this conflict blocks.
  TextColumn get outboxOperationId => text()();

  /// Stable identifier of a `ConflictPolicy` value.
  TextColumn get policy => text()();

  /// JSON-encoded full local snapshot at detection time.
  TextColumn get localSnapshot => text()();

  /// JSON-encoded full remote snapshot at detection time.
  TextColumn get remoteSnapshot => text()();

  /// JSON-encoded list of the business fields that actually diverge.
  TextColumn get conflictingFields => text()();

  /// Stable identifier of a `ConflictRecordStatus` value: `'conflict'` or
  /// `'resolved'`.
  TextColumn get status => text().withDefault(const Constant('conflict'))();

  DateTimeColumn get detectedAt => dateTime()();
  DateTimeColumn get resolvedAt => dateTime().nullable()();
  TextColumn get resolvedBy => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
