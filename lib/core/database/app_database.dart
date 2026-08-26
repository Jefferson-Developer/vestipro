import 'package:drift/drift.dart';

import 'tables/customer_addresses_table.dart';
import 'tables/customer_contacts_table.dart';
import 'tables/customers_table.dart';
import 'tables/favorites_table.dart';
import 'tables/product_search_index_table.dart';

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

class ProductSearchIndexRow {
  const ProductSearchIndexRow({required this.product});

  final ProductSearchIndexTableData product;
}

/// VestiPro local (offline) database.
///
/// TASK-054 seeds this database with the tables needed for the Customer
/// initial offline load. TASK-069 adds [ProductSearchIndexTable] as a narrow
/// read index for product search, not yet the full Product sync schema. The
/// general-purpose local schema for every other offline-capable entity
/// (price tables, orders, Outbox, ...) is EPIC-14 work and must keep extending
/// this same [AppDatabase] class/migration chain rather than create a second
/// local database.
@DriftDatabase(
  tables: [
    CustomersTable,
    CustomerAddressesTable,
    CustomerContactsTable,
    ProductSearchIndexTable,
    FavoritesTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 4;

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
        if (from < 3) {
          await migrator.createTable(productSearchIndexTable);
        }
        if (from < 4) {
          await migrator.createTable(favoritesTable);
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

  Future<void> replaceProductSearchIndex({
    required String organizationId,
    required List<ProductSearchIndexTableCompanion> productRows,
  }) {
    return transaction(() async {
      await (delete(
        productSearchIndexTable,
      )..where((row) => row.organizationId.equals(organizationId))).go();

      await batch((batch) {
        batch.insertAllOnConflictUpdate(productSearchIndexTable, productRows);
      });
    });
  }

  Future<void> upsertProductSearchIndex({
    required ProductSearchIndexTableCompanion productRow,
  }) {
    return into(productSearchIndexTable).insertOnConflictUpdate(productRow);
  }

  Future<List<ProductSearchIndexRow>> searchProductIndex({
    required String organizationId,
    required String normalizedQuery,
    int limit = 20,
  }) async {
    final query = normalizedQuery.trim();
    if (query.isEmpty) return const <ProductSearchIndexRow>[];

    final rows =
        await (select(productSearchIndexTable)
              ..where(
                (row) =>
                    row.organizationId.equals(organizationId) &
                    row.deletedAt.isNull() &
                    row.normalizedSearchText.like('%$query%'),
              )
              ..orderBy([
                (row) => OrderingTerm.desc(row.updatedAt),
                (row) => OrderingTerm.asc(row.name),
              ])
              ..limit(limit))
            .get();

    return rows
        .map((product) => ProductSearchIndexRow(product: product))
        .toList(growable: false);
  }

  /// Favorites [productId] for ([organizationId], [userId]), or resurrects
  /// its tombstone if it was previously soft-deleted (unfavorited) but never
  /// synced — `insertOnConflictUpdate` on the same primary key means a
  /// repeated tap before an earlier write lands only ever updates the same
  /// row, never inserts a duplicate.
  Future<void> upsertFavorite(FavoritesTableCompanion row) {
    return into(favoritesTable).insertOnConflictUpdate(row);
  }

  /// Marks a favorite as pending remote deletion instead of deleting the row
  /// outright, so an unfavorite made while offline is never lost before it
  /// actually syncs. A no-op (0 rows affected) if the favorite does not
  /// exist, keeping unfavoriting idempotent.
  Future<int> softDeleteFavorite({
    required String organizationId,
    required String userId,
    required String productId,
    required DateTime deletedAt,
  }) {
    return (update(favoritesTable)..where(
          (row) =>
              row.organizationId.equals(organizationId) &
              row.userId.equals(userId) &
              row.productId.equals(productId),
        ))
        .write(
          FavoritesTableCompanion(
            deletedAt: Value(deletedAt),
            syncStatus: const Value('pending'),
          ),
        );
  }

  /// Physically removes a favorite row — only ever called once its remote
  /// deletion has been confirmed, never directly by an "unfavorite" tap
  /// (see [softDeleteFavorite]).
  Future<void> deleteFavoriteRow({
    required String organizationId,
    required String userId,
    required String productId,
  }) {
    return (delete(favoritesTable)..where(
          (row) =>
              row.organizationId.equals(organizationId) &
              row.userId.equals(userId) &
              row.productId.equals(productId),
        ))
        .go();
  }

  Future<void> updateFavoriteSyncStatus({
    required String organizationId,
    required String userId,
    required String productId,
    required String syncStatus,
  }) {
    return (update(favoritesTable)..where(
          (row) =>
              row.organizationId.equals(organizationId) &
              row.userId.equals(userId) &
              row.productId.equals(productId),
        ))
        .write(FavoritesTableCompanion(syncStatus: Value(syncStatus)));
  }

  /// Reactive set of every currently favorited (not soft-deleted) Product id
  /// for ([organizationId], [userId]) — re-emits on every local write to
  /// [FavoritesTable] in that scope, which is what lets a favorite button
  /// reflect an add/remove immediately, online or offline.
  Stream<Set<String>> watchFavoriteProductIds({
    required String organizationId,
    required String userId,
  }) {
    final query = select(favoritesTable)
      ..where(
        (row) =>
            row.organizationId.equals(organizationId) &
            row.userId.equals(userId) &
            row.deletedAt.isNull(),
      );
    return query.watch().map(
      (rows) => rows.map((row) => row.productId).toSet(),
    );
  }

  /// Newest-favorited-first page of [FavoritesTable] rows for
  /// ([organizationId], [userId]). Fetches `limit + 1` rows to derive
  /// `hasMore` without a separate count query, mirroring
  /// `FirestoreCollectionDataSource.getPage`'s same trick.
  Future<List<FavoritesTableData>> listFavorites({
    required String organizationId,
    required String userId,
    required int offset,
    required int limit,
  }) {
    return (select(favoritesTable)
          ..where(
            (row) =>
                row.organizationId.equals(organizationId) &
                row.userId.equals(userId) &
                row.deletedAt.isNull(),
          )
          ..orderBy([
            (row) => OrderingTerm.desc(row.createdAt),
            (row) => OrderingTerm.asc(row.productId),
          ])
          ..limit(limit + 1, offset: offset))
        .get();
  }

  /// Every locally pending favorite mutation (add or tombstoned remove) for
  /// ([organizationId], [userId]) — what `DriftFavoriteRepository` drains
  /// opportunistically (e.g. when the favorites/catalog screen starts) to
  /// sync what could not reach Firestore while offline, ahead of a real
  /// connectivity-triggered Outbox (EPIC-14).
  ///
  /// Includes both `pending` (never attempted yet) and `failed` (attempted
  /// but the remote call errored) rows — a `failed` mutation must still be
  /// retried the next time the scope is watched, otherwise a favorite that
  /// failed to sync once would never sync again, even after the connection
  /// comes back.
  Future<List<FavoritesTableData>> listPendingFavoriteSync({
    required String organizationId,
    required String userId,
  }) {
    return (select(favoritesTable)..where(
          (row) =>
              row.organizationId.equals(organizationId) &
              row.userId.equals(userId) &
              (row.syncStatus.equals('pending') |
                  row.syncStatus.equals('failed')),
        ))
        .get();
  }
}
