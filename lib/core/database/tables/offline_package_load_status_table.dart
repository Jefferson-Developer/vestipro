import 'package:drift/drift.dart';

/// Per-entity bookkeeping for the offline package download (TASK-107,
/// EPIC-14 — seção 5.1 de `tasks.md`).
///
/// `DownloadOfflinePackageUseCase` writes exactly one row per
/// `organizationId`/`companyId`/`entityKind` tuple: it marks the row
/// [isComplete] `false` the moment it starts downloading that entity, and
/// only flips it back to `true` (updating [lastCompletedAt]/[recordCount])
/// after the entity's local replace transaction has actually committed.
///
/// This is the "carga incompleta" marker the task requires: a crash, a
/// dropped connection or an explicit cancellation mid-entity always leaves
/// [isComplete] `false` for that entity, so no reader of the local cache
/// (this table, the future Central de Sincronização — TASK-112 — or any
/// screen) can mistake a partially-downloaded entity for a trustworthy,
/// complete offline dataset. It never stores the downloaded rows
/// themselves — those live in each entity's own table (`CustomersTable`,
/// `PriceListsTable`, `PaymentTermsTable`, ...).
@TableIndex(
  name: 'idx_offline_package_load_status_scope',
  columns: {#organizationId, #companyId},
)
class OfflinePackageLoadStatusTable extends Table {
  @override
  String get tableName => 'offline_package_load_status';

  TextColumn get organizationId => text()();
  TextColumn get companyId => text()();

  /// Stable identifier of an [OfflinePackageEntityKind] value (e.g.
  /// `'customers'`) — stored as text rather than an int index so a future
  /// enum reordering can never silently change what an existing row means.
  TextColumn get entityKind => text()();

  BoolColumn get isComplete => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastCompletedAt => dateTime().nullable()();
  IntColumn get recordCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {organizationId, companyId, entityKind};
}
