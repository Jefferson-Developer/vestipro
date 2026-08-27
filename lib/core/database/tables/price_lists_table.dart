import 'package:drift/drift.dart';

/// Local mirror of the `PriceList` aggregate (EPIC-11, TASK-083) used for the
/// offline load of the catalog's pricing tables.
///
/// This is a read-mostly cache: `PriceListLocalStoreRepository` supports
/// both a full idempotent replace (initial load, mirroring
/// `CustomersTable`) and a per-row upsert (incremental update, mirroring
/// `FavoritesTable`), ahead of the generic Outbox/sync engine (EPIC-14).
/// `deletedAt` is a tombstone, never a physical row delete — a soft-deleted
/// Price List must not appear in "active" queries but stays in the local
/// database (TASK-106 seção 5.3 convention, applied here ahead of that
/// task's central schema).
@TableIndex(
  name: 'idx_price_lists_org_company',
  columns: {#organizationId, #companyId},
)
class PriceListsTable extends Table {
  @override
  String get tableName => 'price_lists';

  TextColumn get id => text()();
  TextColumn get organizationId => text()();
  TextColumn get companyId => text()();
  TextColumn get name => text()();
  TextColumn get currency => text()();
  DateTimeColumn get validFrom => dateTime()();
  DateTimeColumn get validTo => dateTime().nullable()();
  TextColumn get status => text()();
  TextColumn get scope => text()();
  TextColumn get scopeValue => text().nullable()();
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
