import 'package:drift/drift.dart';

@TableIndex(
  name: 'idx_warehouses_org_company_branch',
  columns: {#organizationId, #companyId, #branchId},
)
class WarehousesTable extends Table {
  @override
  String get tableName => 'warehouses';

  TextColumn get id => text()();
  TextColumn get organizationId => text()();
  TextColumn get companyId => text()();
  TextColumn get branchId => text().nullable()();
  TextColumn get code => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  BoolColumn get isActive => boolean()();
  IntColumn get priority => integer().withDefault(const Constant(0))();
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
