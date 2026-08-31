import 'package:drift/drift.dart';

/// Local, append-only persistence for [ConflictAuditEntry] (TASK-110,
/// EPIC-14 — seção 5.5 de `tasks.md`: "toda resolução deve ser auditável").
///
/// No update/delete path is ever expected against this table — the same
/// "permanent history" rule as the centralized `AuditLogEntry`'s Firestore
/// collection, just scoped locally to conflict resolution.
@TableIndex(
  name: 'idx_conflict_audit_log_scope',
  columns: {#organizationId, #performedAt},
)
class ConflictAuditLogTable extends Table {
  @override
  String get tableName => 'conflict_audit_log';

  TextColumn get id => text()();
  TextColumn get organizationId => text()();
  TextColumn get companyId => text().nullable()();

  /// Stable identifier of an `OutboxEntityType` value.
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();

  /// Stable identifier of a `ConflictPolicy` value.
  TextColumn get policy => text()();

  /// Stable identifier of a `ConflictAuditOutcome` value.
  TextColumn get outcome => text()();

  /// `'system:sync-engine'` for an automatic resolution, or the resolving
  /// user's id for a manual one (TASK-111).
  TextColumn get actor => text()();

  DateTimeColumn get performedAt => dateTime()();

  /// JSON-encoded list of fields whose losing-side value was discarded
  /// (last-write-wins outcomes only) — `'[]'` otherwise.
  TextColumn get discardedFields => text().withDefault(const Constant('[]'))();

  /// JSON-encoded list of fields that could not be merged automatically —
  /// `'[]'` outside a blocked/resolved-manual outcome.
  TextColumn get conflictingFields =>
      text().withDefault(const Constant('[]'))();

  /// The related `ConflictRecordsTable.id`, when [outcome] is
  /// `blocked_manual`/`resolved_manual`.
  TextColumn get conflictRecordId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
