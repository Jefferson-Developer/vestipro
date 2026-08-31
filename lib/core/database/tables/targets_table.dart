import 'package:drift/drift.dart';

/// Local structural cache for "metas" from `tasks.md` seção 5.1 (TASK-106).
///
/// This is **not** the full `Target` domain schema — that domain model is
/// deliberately deferred to TASK-114 ("Modelar Target", EPIC-15), which owns
/// the metric taxonomy, period rules and achievement calculation. This table
/// only guarantees a goal/quota row can be downloaded and read offline ahead
/// of that task, the same narrow-ahead-of-full-schema precedent already used
/// by `ProductSearchIndexTable` (narrow product search index ahead of the
/// full `Product` sync schema) and `OrdersTable` (structural order cache
/// ahead of the Outbox/sync engine). TASK-114 is expected to extend or adapt
/// this table's columns once the Target domain entity exists, rather than
/// create a second local table for metas.
///
/// [metric] is intentionally a free-form `TextColumn` (e.g. `revenue`,
/// `positivacao`, `units`) since the metric taxonomy is TASK-114's decision,
/// not this task's. [achievedValueCache] is a server-computed snapshot only
/// (never calculated client-side, per the BI/agregação server-side rule) —
/// a `null` value means "not yet synced from the server aggregation".
@TableIndex(
  name: 'idx_targets_org_company',
  columns: {#organizationId, #companyId},
)
@TableIndex(
  name: 'idx_targets_org_owner_period',
  columns: {#organizationId, #ownerId, #periodStart},
)
class TargetsTable extends Table {
  @override
  String get tableName => 'targets';

  TextColumn get id => text()();
  TextColumn get organizationId => text()();
  TextColumn get companyId => text()();
  TextColumn get ownerId => text()();
  DateTimeColumn get periodStart => dateTime()();
  DateTimeColumn get periodEnd => dateTime()();
  TextColumn get metric => text()();
  RealColumn get targetValue => real()();
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
