import 'package:drift/drift.dart';

/// Local mirror of `SizeGridTemplate` (EPIC-08, TASK-071) — the reusable,
/// organization-scoped size grid ("grade comercial" template) — used by the
/// offline load of "grades" from `tasks.md` seção 5.1 (TASK-106).
///
/// [sizesJson] encodes the ordered `List<SizeGridSize>` (`id`,
/// `organizationId`, `label`, `orderScore`) as JSON text, same precedent as
/// `CustomersTable.tagsJson`: nothing needs to query into an individual size
/// at the SQL level today, only load the whole template to resolve a
/// variant's size label/commercial order client-side, mirroring
/// `SizeGridTemplate.orderedSizes`.
///
/// `SizeGridTemplate` has no `companyId` (grids are organization-wide, not
/// per-company), so this table mirrors that shape exactly.
@TableIndex(name: 'idx_size_grids_org', columns: {#organizationId})
class SizeGridsTable extends Table {
  @override
  String get tableName => 'size_grids';

  TextColumn get id => text()();
  TextColumn get organizationId => text()();
  TextColumn get name => text()();
  TextColumn get sizesJson => text().withDefault(const Constant('[]'))();
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
