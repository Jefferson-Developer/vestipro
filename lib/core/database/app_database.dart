import 'package:drift/drift.dart';

import 'tables/customer_addresses_table.dart';
import 'tables/customer_contacts_table.dart';
import 'tables/customers_table.dart';

part 'app_database.g.dart';

/// Result of a join between a customer row and its address/contact rows,
/// already ordered by [CustomerAddressesTable.position] /
/// [CustomerContactsTable.position].
class CustomerWithRelationsRow {
  const CustomerWithRelationsRow({
    required this.customer,
    required this.addresses,
    required this.contacts,
  });

  final CustomersTableData customer;
  final List<CustomerAddressesTableData> addresses;
  final List<CustomerContactsTableData> contacts;
}

/// VestiPro local (offline) database.
///
/// TASK-054 seeds this database with only the tables needed for the Customer
/// initial offline load: [CustomersTable], [CustomerAddressesTable] and
/// [CustomerContactsTable]. It is intentionally scoped to Customers — the
/// general-purpose local schema for every other offline-capable entity
/// (products, price tables, orders, Outbox, ...) is EPIC-14 work
/// (TASK-106/TASK-108/TASK-109) and must extend this same [AppDatabase]
/// class/migration chain rather than create a second local database.
@DriftDatabase(
  tables: [CustomersTable, CustomerAddressesTable, CustomerContactsTable],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (migrator) async {
        await migrator.createAll();
      },
      onUpgrade: (migrator, from, to) async {
        if (from < 2) {
          await migrator.addColumn(
            customersTable,
            customersTable.commercialScore,
          );
          await migrator.addColumn(customersTable, customersTable.healthScore);
          await migrator.addColumn(
            customersTable,
            customersTable.healthScoreBand,
          );
          await migrator.addColumn(
            customersTable,
            customersTable.scoreUpdatedAt,
          );
          await migrator.addColumn(
            customersTable,
            customersTable.scoreFormulaVersion,
          );
          await migrator.addColumn(
            customersTable,
            customersTable.scoreDataCoverage,
          );
        }
      },
      beforeOpen: (details) async {
        // Required for `ON DELETE CASCADE` on the address/contact foreign
        // keys to actually take effect on SQLite.
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  /// Replaces the full local customer set for a tenant/company scope with
  /// [customerRows]/[addressRows]/[contactRows] in a single transaction.
  ///
  /// This is the "carga inicial completa filtrada" primitive TASK-054 asks
  /// for: the caller (`LoadInitialCustomerOfflineDataUseCase`) is expected to
  /// have already resolved which customers the signed-in user may see
  /// (RBAC/portfolio) before calling this method, so this method itself does
  /// not filter by role — it only guarantees the on-device table matches
  /// exactly the set it is given for that `organizationId`/`companyId`.
  ///
  /// Deleting matching rows from [CustomersTable] cascades to their address
  /// and contact rows (`ON DELETE CASCADE`), so this method does not need to
  /// delete from the child tables directly.
  ///
  /// Extension point for TASK-109 (incremental sync engine): that task can
  /// call `batch(...)` with `insertOnConflictUpdate` directly against these
  /// same tables to merge incremental changes instead of replacing the whole
  /// set, without needing a schema change here.
  Future<void> replaceCustomers({
    required String organizationId,
    required String companyId,
    required List<CustomersTableCompanion> customerRows,
    required List<CustomerAddressesTableCompanion> addressRows,
    required List<CustomerContactsTableCompanion> contactRows,
  }) {
    return transaction(() async {
      await (delete(customersTable)..where(
            (row) =>
                row.organizationId.equals(organizationId) &
                row.companyId.equals(companyId),
          ))
          .go();

      await batch((batch) {
        batch.insertAll(customersTable, customerRows);
        batch.insertAll(customerAddressesTable, addressRows);
        batch.insertAll(customerContactsTable, contactRows);
      });
    });
  }

  /// Returns every locally stored customer for [organizationId]/[companyId],
  /// each paired with its ordered address/contact rows.
  Future<List<CustomerWithRelationsRow>> getCustomersForCompany({
    required String organizationId,
    required String companyId,
  }) async {
    final customerRows =
        await (select(customersTable)..where(
              (row) =>
                  row.organizationId.equals(organizationId) &
                  row.companyId.equals(companyId),
            ))
            .get();

    final results = <CustomerWithRelationsRow>[];
    for (final customerRow in customerRows) {
      final addressRows =
          await (select(customerAddressesTable)
                ..where((row) => row.customerId.equals(customerRow.id))
                ..orderBy([(row) => OrderingTerm.asc(row.position)]))
              .get();
      final contactRows =
          await (select(customerContactsTable)
                ..where((row) => row.customerId.equals(customerRow.id))
                ..orderBy([(row) => OrderingTerm.asc(row.position)]))
              .get();
      results.add(
        CustomerWithRelationsRow(
          customer: customerRow,
          addresses: addressRows,
          contacts: contactRows,
        ),
      );
    }
    return results;
  }

  /// Number of customers currently stored locally for [organizationId]/
  /// [companyId]. Used to surface the size of the offline load without
  /// materializing every row.
  Future<int> countCustomersForCompany({
    required String organizationId,
    required String companyId,
  }) async {
    final countExpression = customersTable.id.count();
    final query = selectOnly(customersTable)
      ..addColumns([countExpression])
      ..where(
        customersTable.organizationId.equals(organizationId) &
            customersTable.companyId.equals(companyId),
      );
    final row = await query.getSingle();
    return row.read(countExpression) ?? 0;
  }
}
