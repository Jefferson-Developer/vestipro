import 'package:drift/drift.dart';

/// Local mirror of the full `Product` aggregate (EPIC-08) — the canonical
/// offline cache TASK-106 adds for "produtos" from `tasks.md` seção 5.1,
/// used by offline order creation/grade comercial screens that need to
/// resolve a product's full record, not just a search-result projection.
///
/// This is distinct from [ProductSearchIndexTable] (TASK-069), which stays a
/// narrow, read-optimized index for the global product search box and is not
/// touched by this migration — both tables are kept in sync by the same
/// future product sync path (EPIC-14 sync engine, TASK-109), each serving a
/// different read pattern, the same way `VariantStockBalancesTable` and
/// `InventorySnapshotsTable`-equivalent data coexist for different queries.
///
/// [tagsJson]/[colorIdsJson]/[mediaJson]/[customFieldValuesJson] encode their
/// respective `List<...>` domain fields as JSON text, same precedent as
/// `CustomersTable.tagsJson`.
@TableIndex(
  name: 'idx_products_org_company',
  columns: {#organizationId, #companyId},
)
@TableIndex(name: 'idx_products_org_sku', columns: {#organizationId, #sku})
class ProductsTable extends Table {
  @override
  String get tableName => 'products';

  TextColumn get id => text()();
  TextColumn get organizationId => text()();
  TextColumn get companyId => text().nullable()();
  TextColumn get sku => text()();
  TextColumn get reference => text()();
  TextColumn get name => text()();
  TextColumn get shortDescription => text().nullable()();
  TextColumn get fullDescription => text().nullable()();
  TextColumn get brand => text().nullable()();
  TextColumn get collectionId => text().nullable()();
  TextColumn get seasonId => text().nullable()();
  TextColumn get line => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get subcategoryId => text().nullable()();
  TextColumn get gender => text().nullable()();
  TextColumn get targetAudience => text().nullable()();
  TextColumn get fabric => text().nullable()();
  TextColumn get composition => text().nullable()();
  TextColumn get supplierId => text().nullable()();
  TextColumn get ncm => text().nullable()();
  TextColumn get ean => text().nullable()();
  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();
  TextColumn get colorIdsJson => text().withDefault(const Constant('[]'))();
  TextColumn get sizeGridTemplateId => text().nullable()();
  TextColumn get status => text()();
  DateTimeColumn get launchDate => dateTime().nullable()();
  TextColumn get seoTitle => text().nullable()();
  TextColumn get seoDescription => text().nullable()();
  TextColumn get seoSlug => text().nullable()();
  TextColumn get mediaJson => text().withDefault(const Constant('[]'))();
  TextColumn get customFieldValuesJson =>
      text().withDefault(const Constant('[]'))();
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
