import 'package:drift/drift.dart';

/// Local mirror of the `Customer` aggregate (EPIC-06, TASK-048) used for the
/// initial offline load (TASK-054).
///
/// This is a read-mostly cache populated by
/// `LoadInitialCustomerOfflineDataUseCase`: it holds exactly the customers the
/// signed-in user is allowed to see offline, scoped by
/// `organizationId`/`companyId` and the portfolio/RBAC selection resolved by
/// `PortfolioVisibilityService`. `tags`/`customFields` are stored as JSON text
/// because Drift has no native list/map column type.
///
/// The generic sync engine (Outbox, incremental cursor, conflict resolution)
/// is out of scope here and belongs to EPIC-14 (TASK-108/TASK-109); this
/// table only needs to support a full, idempotent replace of the local
/// customer set today, which is why rows are keyed by the same [id] the
/// server/domain entity uses.
@TableIndex(
  name: 'idx_customers_org_company',
  columns: {#organizationId, #companyId},
)
class CustomersTable extends Table {
  @override
  String get tableName => 'customers';

  TextColumn get id => text()();
  TextColumn get organizationId => text()();
  TextColumn get companyId => text()();
  TextColumn get type => text()();
  TextColumn get document => text()();
  TextColumn get legalName => text().nullable()();
  TextColumn get tradeName => text().nullable()();
  TextColumn get fullName => text().nullable()();
  TextColumn get stateRegistration => text().nullable()();
  TextColumn get primaryEmail => text().nullable()();
  TextColumn get primaryPhone => text().nullable()();
  TextColumn get status => text()();
  TextColumn get classification => text().nullable()();
  TextColumn get potential => text().nullable()();
  TextColumn get segment => text().nullable()();
  TextColumn get originChannel => text().nullable()();
  TextColumn get responsibleSellerId => text().nullable()();
  DateTimeColumn get registeredAt => dateTime()();
  DateTimeColumn get lastPurchaseAt => dateTime().nullable()();
  IntColumn get commercialScore => integer().nullable()();
  IntColumn get healthScore => integer().nullable()();
  TextColumn get healthScoreBand => text().nullable()();
  DateTimeColumn get scoreUpdatedAt => dateTime().nullable()();
  TextColumn get scoreFormulaVersion => text().nullable()();
  TextColumn get scoreDataCoverage => text().nullable()();
  TextColumn get tagsJson => text().nullable()();
  TextColumn get customFieldsJson => text().nullable()();
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
