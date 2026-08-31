import 'package:drift/drift.dart';

/// Local mirror of `ProductColor` (EPIC-08, TASK-070) — the reusable,
/// organization-scoped color palette entry — used by the offline load of
/// "cores" from `tasks.md` seção 5.1 (TASK-106).
///
/// [additionalImageUrlsJson]/[eansJson] encode `List<String>`/`List<Ean>`
/// respectively, same JSON-column precedent as `CustomersTable.tagsJson`:
/// there is nothing that needs to query into those lists at the SQL level.
///
/// `ProductColor` has no `companyId` (colors are organization-wide, not
/// per-company) and no `deletedAt`-independent soft delete flag beyond
/// [status]/[deletedAt] already present on the domain entity, so this table
/// mirrors that shape exactly rather than forcing the generic template's
/// `companyId` column where the domain has none.
@TableIndex(name: 'idx_colors_org', columns: {#organizationId})
class ColorsTable extends Table {
  @override
  String get tableName => 'colors';

  TextColumn get id => text()();
  TextColumn get organizationId => text()();
  TextColumn get code => text()();
  TextColumn get name => text()();
  TextColumn get hex => text()();
  TextColumn get mainImageUrl => text().nullable()();
  TextColumn get additionalImageUrlsJson =>
      text().withDefault(const Constant('[]'))();
  TextColumn get eansJson => text().withDefault(const Constant('[]'))();
  TextColumn get status => text()();
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
