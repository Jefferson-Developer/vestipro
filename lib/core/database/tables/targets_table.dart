import 'package:drift/drift.dart';

/// Local offline cache for `Target` ("meta comercial", EPIC-15/TASK-114).
///
/// TASK-106 created this table as a narrow structural placeholder ahead of
/// the full `Target` domain model (`lib/features/targets/domain/entities/
/// target.dart`), the same narrow-ahead-of-full-schema precedent already
/// used by `ProductSearchIndexTable` and `OrdersTable`. TASK-114 extends it
/// to match that domain model: [dimensionId] is the TASK-106 `ownerId`
/// column renamed (same physical data, broader meaning — a Target's
/// dimension reference is not always a "user"), and [dimensionType],
/// [periodGranularity], [currency] and [status] are new columns.
///
/// [dimensionType], [periodGranularity], [currency] and [status] are
/// nullable here even though the domain entity requires all of them: this
/// table is still only a local *cache*, and no download/sync pipeline
/// populates it yet (that wiring — mirroring
/// `DriftCustomerLocalStoreRepository` — is out of TASK-114's scope, a
/// "modelar" task, not an "implementar oferta offline completa" one). A
/// `null` value in any of them means "row written before TASK-114's columns
/// existed, not yet backfilled by a full sync", not a valid domain state.
///
/// [metric] stores the free-form `TargetMetricType` code (e.g. `revenue`,
/// `positivacao`, `quantity`) exactly like before — the metric taxonomy is
/// deliberately extensible without a schema change, see
/// `TargetMetricType`'s docs. [achievedValueCache] remains a server-computed
/// snapshot only (never calculated client-side, per the BI/agregação
/// server-side rule) — a `null` value means "not yet synced from the server
/// aggregation".
@TableIndex(
  name: 'idx_targets_org_company',
  columns: {#organizationId, #companyId},
)
@TableIndex(
  name: 'idx_targets_org_dimension_period',
  columns: {#organizationId, #dimensionId, #periodStart},
)
class TargetsTable extends Table {
  @override
  String get tableName => 'targets';

  TextColumn get id => text()();
  TextColumn get organizationId => text()();
  TextColumn get companyId => text()();
  TextColumn get dimensionId => text()();
  TextColumn get dimensionType => text().nullable()();
  DateTimeColumn get periodStart => dateTime()();
  DateTimeColumn get periodEnd => dateTime()();
  TextColumn get periodGranularity => text().nullable()();
  TextColumn get metric => text()();
  RealColumn get targetValue => real()();
  TextColumn get currency => text().nullable()();
  TextColumn get status => text().nullable()();
  RealColumn get achievedValueCache => real().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get createdBy => text()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get updatedBy => text()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get version => integer()();
  TextColumn get syncStatus => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
