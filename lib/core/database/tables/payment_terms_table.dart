import 'package:drift/drift.dart';

@TableIndex(
  name: 'idx_payment_terms_org_company',
  columns: {#organizationId, #companyId},
)
class PaymentTermsTable extends Table {
  @override
  String get tableName => 'payment_terms';

  TextColumn get id => text()();
  TextColumn get organizationId => text()();
  TextColumn get companyId => text()();
  TextColumn get name => text()();
  TextColumn get installmentsJson => text()();
  RealColumn get averageTermDays => real()();
  TextColumn get status => text()();
  TextColumn get priceListIdsJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get createdBy => text()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get updatedBy => text()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
