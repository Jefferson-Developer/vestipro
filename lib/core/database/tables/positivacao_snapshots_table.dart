import 'package:drift/drift.dart';

/// Local offline cache for the positivação snapshot (TASK-117, EPIC-15/
/// VESTI-087) — one row per organization/company/dimension/period, mirroring
/// the "narrow cache, no pipeline populates it yet" precedent
/// `TargetsTable.achievedValueCache` already set for TASK-116.
///
/// [totalPortfolio]/[positivatedCount]/[calculatedAt] are nullable and always
/// either all `null` (row written but never calculated by an aggregation
/// pipeline yet — the expected state today, see `PositivacaoSnapshot`'s own
/// docs) or all set together — never a partial/inconsistent row.
/// [nonPositivatedCustomerIdsJson] encodes a `List<String>` as JSON text,
/// same convention as `CustomersTable.tagsJson`.
///
/// [id] is a deterministic composite key
/// (`'$organizationId:$dimensionType:$dimensionId:${periodStart.toIso8601String()}'`)
/// built by `DriftPositivacaoRepository`, never user-supplied — this keeps
/// the table's primary key a single column like every other table here while
/// still letting `upsertPositivacaoSnapshot` behave as a natural-key upsert.
@TableIndex(
  name: 'idx_positivacao_snapshots_org_company',
  columns: {#organizationId, #companyId},
)
class PositivacaoSnapshotsTable extends Table {
  @override
  String get tableName => 'positivacao_snapshots';

  TextColumn get id => text()();
  TextColumn get organizationId => text()();
  TextColumn get companyId => text()();
  TextColumn get dimensionType => text()();
  TextColumn get dimensionId => text()();
  DateTimeColumn get periodStart => dateTime()();
  DateTimeColumn get periodEnd => dateTime()();
  IntColumn get totalPortfolio => integer().nullable()();
  IntColumn get positivatedCount => integer().nullable()();
  TextColumn get nonPositivatedCustomerIdsJson => text().nullable()();
  DateTimeColumn get calculatedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
