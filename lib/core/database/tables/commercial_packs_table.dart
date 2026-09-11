import 'package:drift/drift.dart';

/// Local mirror of the `CommercialPack` aggregate (TASK-207, EPIC-32) used
/// for the offline load of kits/pacotes/sortimentos.
///
/// This is a read-mostly cache, same shape as `PriceListsTable`: supports
/// both a full idempotent replace (initial load) and a per-row upsert
/// (incremental update), ahead of the generic Outbox/sync engine (EPIC-14).
/// [deletedAt] is a tombstone, never a physical row delete.
///
/// [componentsJson]/[assortmentRulesJson] encode their respective nested
/// list fields (`PackComponent`/`AssortmentRule`) as JSON text, same
/// precedent `CampaignsTable.productIdsJson` already sets — nothing needs
/// to query into an individual component/rule at the SQL level, only load
/// the whole pack to evaluate its composition client-side.
///
/// [companyId] is nullable — a pack scoped to every company of the
/// organization leaves it `null`, same nullable-company precedent
/// `ProductsTable` already uses.
@TableIndex(
  name: 'idx_commercial_packs_org_company',
  columns: {#organizationId, #companyId},
)
@TableIndex(
  name: 'idx_commercial_packs_org_pack_code',
  columns: {#organizationId, #packCode},
)
class CommercialPacksTable extends Table {
  @override
  String get tableName => 'commercial_packs';

  TextColumn get id => text()();
  TextColumn get organizationId => text()();
  TextColumn get companyId => text().nullable()();
  TextColumn get packCode => text()();
  IntColumn get version => integer()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get packType => text()();
  TextColumn get status => text()();
  TextColumn get pricingPolicyType => text()();
  RealColumn get fixedPrice => real().nullable()();
  RealColumn get discountPercentage => real().nullable()();
  TextColumn get bonusComponentId => text().nullable()();
  TextColumn get stockPolicyType => text()();
  TextColumn get dedicatedWarehouseId => text().nullable()();
  TextColumn get collectionId => text().nullable()();
  TextColumn get campaignId => text().nullable()();
  TextColumn get customerSegment => text().nullable()();
  TextColumn get channel => text().nullable()();
  DateTimeColumn get validFrom => dateTime()();
  DateTimeColumn get validTo => dateTime().nullable()();
  TextColumn get componentsJson => text().withDefault(const Constant('[]'))();
  TextColumn get assortmentRulesJson =>
      text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get createdBy => text()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get updatedBy => text()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get supersededByPackId => text().nullable()();
  TextColumn get syncStatus => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
