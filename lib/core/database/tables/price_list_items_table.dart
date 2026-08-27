import 'package:drift/drift.dart';

/// Local mirror of `PriceListItem` (TASK-084) used by the catalog's offline
/// pricing cache. The composite business key is encoded in [id] so the local
/// store can upsert one product-level row or one variant exception row without
/// creating duplicates.
@TableIndex(
  name: 'idx_price_list_items_org_company_price_list',
  columns: {#organizationId, #companyId, #priceListId},
)
@TableIndex(
  name: 'idx_price_list_items_org_product',
  columns: {#organizationId, #companyId, #productId},
)
class PriceListItemsTable extends Table {
  @override
  String get tableName => 'price_list_items';

  TextColumn get id => text()();
  TextColumn get organizationId => text()();
  TextColumn get companyId => text()();
  TextColumn get priceListId => text()();
  TextColumn get productId => text()();
  TextColumn get variantId => text().nullable()();
  RealColumn get price => real()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get updatedBy => text()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
