import 'package:drift/drift.dart';

import 'customers_table.dart';

/// Local mirror of `Customer.contacts` (TASK-050), one row per contact,
/// scoped to the parent customer row from [CustomersTable].
///
/// See [CustomerAddressesTable] for why `organizationId`/`companyId` are
/// denormalized here and why [position] exists.
@TableIndex(name: 'idx_customer_contacts_customer', columns: {#customerId})
class CustomerContactsTable extends Table {
  @override
  String get tableName => 'customer_contacts';

  TextColumn get id => text()();
  TextColumn get customerId =>
      text().references(CustomersTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get organizationId => text()();
  TextColumn get companyId => text()();
  TextColumn get typeCode => text()();
  TextColumn get typeLabel => text()();
  TextColumn get name => text()();
  TextColumn get role => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();
  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
