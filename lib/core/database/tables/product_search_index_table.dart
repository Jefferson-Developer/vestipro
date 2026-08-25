import 'package:drift/drift.dart';

/// Local read index for global Product search (TASK-069).
///
/// This is not the full Product sync schema from EPIC-14. It is a compact,
/// read-optimized mirror populated by the current/future product sync path so
/// representatives can search the catalog offline without trusting stale
/// remote state. The primary key remains scoped by organization to preserve
/// tenant isolation even if two tenants reuse the same upstream product id.
@TableIndex(
  name: 'idx_product_search_index_org_text',
  columns: {#organizationId, #normalizedSearchText},
)
class ProductSearchIndexTable extends Table {
  @override
  String get tableName => 'product_search_index';

  TextColumn get productId => text()();
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
  TextColumn get tagsJson => text()();
  TextColumn get status => text()();
  DateTimeColumn get launchDate => dateTime().nullable()();
  TextColumn get seoTitle => text().nullable()();
  TextColumn get seoDescription => text().nullable()();
  TextColumn get seoSlug => text().nullable()();
  TextColumn get mediaJson => text()();
  TextColumn get customFieldValuesJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get createdBy => text()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get updatedBy => text()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get version => integer()();
  TextColumn get syncStatus => text()();
  TextColumn get normalizedSearchText => text()();
  DateTimeColumn get indexedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {organizationId, productId};
}
