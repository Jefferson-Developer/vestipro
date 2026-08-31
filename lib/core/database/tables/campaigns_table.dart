import 'package:drift/drift.dart';

/// Local mirror of `PromotionalCampaign` (EPIC-11) used by the offline load
/// of "campanhas" from `tasks.md` seção 5.1 (TASK-106) — so catalog/pricing
/// screens can resolve active campaigns without connectivity, mirroring
/// `PriceListsTable`'s role for tabelas de preço.
///
/// [productIdsJson]/[collectionIdsJson]/[categoryIdsJson] encode their
/// respective `List<String>` scope fields as JSON text, same precedent as
/// `CustomersTable.tagsJson` — nothing needs to query into an individual id
/// at the SQL level, only load the whole campaign to evaluate
/// `PromotionalCampaign.matchesProduct` client-side.
@TableIndex(
  name: 'idx_campaigns_org_company',
  columns: {#organizationId, #companyId},
)
@TableIndex(
  name: 'idx_campaigns_org_status',
  columns: {#organizationId, #status},
)
class CampaignsTable extends Table {
  @override
  String get tableName => 'campaigns';

  TextColumn get id => text()();
  TextColumn get organizationId => text()();
  TextColumn get companyId => text()();
  TextColumn get name => text()();
  DateTimeColumn get validFrom => dateTime()();
  DateTimeColumn get validTo => dateTime()();
  TextColumn get customerSegment => text()();
  TextColumn get productIdsJson => text().withDefault(const Constant('[]'))();
  TextColumn get collectionIdsJson =>
      text().withDefault(const Constant('[]'))();
  TextColumn get categoryIdsJson => text().withDefault(const Constant('[]'))();
  TextColumn get discountType => text()();
  RealColumn get discountValue => real()();
  BoolColumn get stackableWithOtherCampaigns => boolean()();
  IntColumn get priority => integer().withDefault(const Constant(0))();
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
