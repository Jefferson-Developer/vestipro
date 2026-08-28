import 'package:drift/drift.dart';

@TableIndex(
  name: 'idx_variant_stock_balances_org_variant',
  columns: {#organizationId, #variantId},
)
@TableIndex(
  name: 'idx_variant_stock_balances_org_warehouse',
  columns: {#organizationId, #warehouseId},
)
class VariantStockBalancesTable extends Table {
  @override
  String get tableName => 'variant_stock_balances';

  TextColumn get id => text()();
  TextColumn get organizationId => text()();
  TextColumn get companyId => text()();
  TextColumn get productId => text()();
  TextColumn get variantId => text()();
  TextColumn get warehouseId => text()();
  IntColumn get physicalQuantity => integer()();
  IntColumn get reservedQuantity => integer()();
  IntColumn get blockedQuantity => integer()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get updatedBy => text()();
  TextColumn get lastSource => text()();
  IntColumn get version => integer()();
  DateTimeColumn get cacheFetchedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
