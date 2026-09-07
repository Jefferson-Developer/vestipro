import 'package:drift/drift.dart';

import 'customers_table.dart';

/// Local mirror of `Customer.addresses` (TASK-050), one row per address,
/// scoped to the parent customer row from [CustomersTable].
///
/// `organizationId`/`companyId` are denormalized from the parent customer so
/// the initial-load replace/read queries in TASK-054 do not need a join to
/// stay tenant-scoped. [position] preserves the original list order from the
/// domain entity, since SQL row order is not guaranteed otherwise.
@TableIndex(name: 'idx_customer_addresses_customer', columns: {#customerId})
class CustomerAddressesTable extends Table {
  @override
  String get tableName => 'customer_addresses';

  TextColumn get id => text()();
  TextColumn get customerId =>
      text().references(CustomersTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get organizationId => text()();
  TextColumn get companyId => text()();
  TextColumn get typeCode => text()();
  TextColumn get typeLabel => text()();
  TextColumn get street => text()();
  TextColumn get number => text().nullable()();
  TextColumn get complement => text().nullable()();
  TextColumn get district => text().nullable()();
  TextColumn get city => text()();
  TextColumn get state => text()();
  TextColumn get zipCode => text()();
  TextColumn get country => text()();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();
  IntColumn get position => integer().withDefault(const Constant(0))();

  // TASK-176: geocoded pin location for the customer map. `latitude`/
  // `longitude` are only meaningful when `geocodingStatusCode == 'geocoded'`;
  // an address created before this feature existed reads back as 'pending'
  // (eligible for the backfill job), never as a silent failure.
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  TextColumn get geocodingStatusCode =>
      text().withDefault(const Constant('pending'))();
  DateTimeColumn get geocodedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
