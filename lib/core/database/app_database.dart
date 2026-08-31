import 'package:drift/drift.dart';

import 'tables/campaigns_table.dart';
import 'tables/colors_table.dart';
import 'tables/conflict_audit_log_table.dart';
import 'tables/conflict_records_table.dart';
import 'tables/customer_addresses_table.dart';
import 'tables/customer_contacts_table.dart';
import 'tables/customers_table.dart';
import 'tables/favorites_table.dart';
import 'tables/offline_package_load_status_table.dart';
import 'tables/order_items_table.dart';
import 'tables/orders_table.dart';
import 'tables/outbox_table.dart';
import 'tables/payment_terms_table.dart';
import 'tables/price_list_items_table.dart';
import 'tables/price_lists_table.dart';
import 'tables/product_search_index_table.dart';
import 'tables/product_variants_table.dart';
import 'tables/products_table.dart';
import 'tables/size_grids_table.dart';
import 'tables/sync_cursors_table.dart';
import 'tables/targets_table.dart';
import 'tables/variant_stock_balances_table.dart';
import 'tables/warehouses_table.dart';

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

/// Result of a join between an order row and its item rows (`OrderItemsTable`),
/// already ordered by [OrderItemsTable.position].
class OrderWithItemsRow {
  const OrderWithItemsRow({required this.order, required this.items});

  final OrdersTableData order;
  final List<OrderItemsTableData> items;
}

/// VestiPro local (offline) database.
///
/// TASK-054 seeds this database with the tables needed for the Customer
/// initial offline load. TASK-069 adds [ProductSearchIndexTable] as a narrow
/// read index for product search, not yet the full Product sync schema.
/// TASK-083 adds [PriceListsTable] as the offline cache for pricing tables.
/// TASK-084 extends that cache with [PriceListItemsTable] for resolved base
/// prices and variant-specific exceptions.
/// TASK-095 adds [OrdersTable]/[OrderItemsTable] as the base structural
/// offline cache for the `Order`/`OrderItem` aggregate (EPIC-13) — no
/// submission/sync-engine behavior yet, that is EPIC-14 (Outbox) work, which
/// must keep extending this same [AppDatabase] class/migration chain rather
/// than create a second local database.
/// TASK-107 adds [OfflinePackageLoadStatusTable], the per-entity "carga
/// completa"/"carga incompleta" marker `DownloadOfflinePackageUseCase` reads
/// and writes around every entity it downloads.
/// TASK-108 adds [OutboxTable], the Outbox Pattern queue of offline write
/// operations pending synchronization (EPIC-14) — the sync engine
/// (TASK-109) and Central de Sincronização (TASK-112) read/drain this same
/// table rather than a second local database.
/// TASK-109 adds [SyncCursorsTable], the per-entity incremental pull
/// bookmark `SyncEngine.runPull` reads/writes so a sync cycle only fetches
/// what changed since the last one instead of the whole remote collection
/// again.
/// TASK-110 adds [ConflictRecordsTable] (a conflict `ConflictResolutionService`
/// could not resolve automatically, kept for TASK-111's manual resolution
/// screen) and [ConflictAuditLogTable] (the local, append-only audit trail
/// of every conflict resolution decision, automatic or manual).
@DriftDatabase(
  tables: [
    CustomersTable,
    CustomerAddressesTable,
    CustomerContactsTable,
    ProductSearchIndexTable,
    FavoritesTable,
    PaymentTermsTable,
    PriceListsTable,
    PriceListItemsTable,
    WarehousesTable,
    VariantStockBalancesTable,
    OrdersTable,
    OrderItemsTable,
    ColorsTable,
    SizeGridsTable,
    ProductsTable,
    ProductVariantsTable,
    CampaignsTable,
    TargetsTable,
    OfflinePackageLoadStatusTable,
    OutboxTable,
    SyncCursorsTable,
    ConflictRecordsTable,
    ConflictAuditLogTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 17;

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
        if (from < 5) {
          await migrator.createTable(priceListsTable);
        }
        if (from < 6) {
          await migrator.createTable(priceListItemsTable);
        }
        if (from < 7) {
          await migrator.createTable(paymentTermsTable);
        }
        if (from < 8) {
          await migrator.createTable(warehousesTable);
        }
        if (from < 9) {
          await migrator.createTable(variantStockBalancesTable);
        }
        if (from < 10) {
          await migrator.createTable(ordersTable);
          await migrator.createTable(orderItemsTable);
        }
        if (from < 11) {
          await migrator.addColumn(ordersTable, ordersTable.orderNumber);
        }
        if (from < 12) {
          await migrator.addColumn(
            ordersTable,
            ordersTable.duplicatedFromOrderId,
          );
          await migrator.addColumn(
            ordersTable,
            ordersTable.duplicatedFromOrderNumber,
          );
        }
        if (from < 13) {
          // TASK-106: schema local Drift completo para a carga offline
          // (seção 5.1 de tasks.md) — cores, grades, produtos, variantes,
          // campanhas e o placeholder estrutural de metas (TASK-114).
          await migrator.createTable(colorsTable);
          await migrator.createTable(sizeGridsTable);
          await migrator.createTable(productsTable);
          await migrator.createTable(productVariantsTable);
          await migrator.createTable(campaignsTable);
          await migrator.createTable(targetsTable);
        }
        if (from < 14) {
          // TASK-107: marcador de status ("carga completa"/"carga
          // incompleta") por entidade do pacote de carga offline.
          await migrator.createTable(offlinePackageLoadStatusTable);
        }
        if (from < 15) {
          // TASK-108: fila local (Outbox) de operações offline pendentes de
          // sincronização.
          await migrator.createTable(outboxTable);
        }
        if (from < 16) {
          // TASK-109: bookmark de cursor por entidade para o pull
          // incremental do motor de sincronização.
          await migrator.createTable(syncCursorsTable);
        }
        if (from < 17) {
          // TASK-110: registros de conflito pendentes de resolução manual e
          // trilha de auditoria local de toda resolução de conflito.
          await migrator.createTable(conflictRecordsTable);
          await migrator.createTable(conflictAuditLogTable);
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

  /// Replaces the full local Price List set for [organizationId]/
  /// [companyId] with exactly [priceListRows] in a single transaction — the
  /// "carga inicial" primitive `PriceListLocalStoreRepository.replaceInitialLoad`
  /// (TASK-083) needs, mirroring [replaceCustomers].
  Future<void> replacePriceLists({
    required String organizationId,
    required String companyId,
    required List<PriceListsTableCompanion> priceListRows,
  }) {
    return transaction(() async {
      await (delete(priceListsTable)..where(
            (row) =>
                row.organizationId.equals(organizationId) &
                row.companyId.equals(companyId),
          ))
          .go();

      await batch((batch) {
        batch.insertAll(priceListsTable, priceListRows);
      });
    });
  }

  /// Inserts or updates exactly one Price List row — the incremental-update
  /// primitive the future sync engine (EPIC-14) uses to keep the local
  /// cache fresh after the initial load, mirroring [upsertFavorite].
  Future<void> upsertPriceList(PriceListsTableCompanion row) {
    return into(priceListsTable).insertOnConflictUpdate(row);
  }

  /// Every non-soft-deleted Price List currently stored locally for
  /// [organizationId]/[companyId].
  Future<List<PriceListsTableData>> getPriceListsForCompany({
    required String organizationId,
    required String companyId,
  }) {
    return (select(priceListsTable)..where(
          (row) =>
              row.organizationId.equals(organizationId) &
              row.companyId.equals(companyId) &
              row.deletedAt.isNull(),
        ))
        .get();
  }

  /// Number of non-soft-deleted Price Lists currently stored locally for
  /// [organizationId]/[companyId], without materializing every row.
  Future<int> countPriceListsForCompany({
    required String organizationId,
    required String companyId,
  }) async {
    final countExpression = priceListsTable.id.count();
    final query = selectOnly(priceListsTable)
      ..addColumns([countExpression])
      ..where(
        priceListsTable.organizationId.equals(organizationId) &
            priceListsTable.companyId.equals(companyId) &
            priceListsTable.deletedAt.isNull(),
      );
    final row = await query.getSingle();
    return row.read(countExpression) ?? 0;
  }

  Future<void> replacePriceListItems({
    required String organizationId,
    required String companyId,
    required String priceListId,
    required List<PriceListItemsTableCompanion> itemRows,
  }) {
    return transaction(() async {
      await (delete(priceListItemsTable)..where(
            (row) =>
                row.organizationId.equals(organizationId) &
                row.companyId.equals(companyId) &
                row.priceListId.equals(priceListId),
          ))
          .go();

      await batch((batch) {
        batch.insertAll(priceListItemsTable, itemRows);
      });
    });
  }

  Future<void> upsertPriceListItem(PriceListItemsTableCompanion row) {
    return into(priceListItemsTable).insertOnConflictUpdate(row);
  }

  Future<List<PriceListItemsTableData>> getPriceListItemsByPriceList({
    required String organizationId,
    required String companyId,
    required String priceListId,
  }) {
    return (select(priceListItemsTable)..where(
          (row) =>
              row.organizationId.equals(organizationId) &
              row.companyId.equals(companyId) &
              row.priceListId.equals(priceListId) &
              row.deletedAt.isNull(),
        ))
        .get();
  }

  Future<List<PriceListItemsTableData>> getPriceListItemsByProduct({
    required String organizationId,
    required String companyId,
    required String productId,
  }) {
    return (select(priceListItemsTable)..where(
          (row) =>
              row.organizationId.equals(organizationId) &
              row.companyId.equals(companyId) &
              row.productId.equals(productId) &
              row.deletedAt.isNull(),
        ))
        .get();
  }

  Future<void> replacePaymentTerms({
    required String organizationId,
    required String companyId,
    required List<PaymentTermsTableCompanion> paymentTermRows,
  }) {
    return transaction(() async {
      await (delete(paymentTermsTable)..where(
            (row) =>
                row.organizationId.equals(organizationId) &
                row.companyId.equals(companyId),
          ))
          .go();

      await batch((batch) {
        batch.insertAll(paymentTermsTable, paymentTermRows);
      });
    });
  }

  Future<void> upsertPaymentTerm(PaymentTermsTableCompanion row) {
    return into(paymentTermsTable).insertOnConflictUpdate(row);
  }

  Future<List<PaymentTermsTableData>> getPaymentTermsForCompany({
    required String organizationId,
    required String companyId,
  }) {
    return (select(paymentTermsTable)..where(
          (row) =>
              row.organizationId.equals(organizationId) &
              row.companyId.equals(companyId) &
              row.deletedAt.isNull(),
        ))
        .get();
  }

  Future<int> countPaymentTermsForCompany({
    required String organizationId,
    required String companyId,
  }) async {
    final countExpression = paymentTermsTable.id.count();
    final query = selectOnly(paymentTermsTable)
      ..addColumns([countExpression])
      ..where(
        paymentTermsTable.organizationId.equals(organizationId) &
            paymentTermsTable.companyId.equals(companyId) &
            paymentTermsTable.deletedAt.isNull(),
      );
    final row = await query.getSingle();
    return row.read(countExpression) ?? 0;
  }

  Future<void> replaceWarehouses({
    required String organizationId,
    required String companyId,
    required List<WarehousesTableCompanion> warehouseRows,
  }) {
    return transaction(() async {
      await (delete(warehousesTable)..where(
            (row) =>
                row.organizationId.equals(organizationId) &
                row.companyId.equals(companyId),
          ))
          .go();

      await batch((batch) {
        batch.insertAll(warehousesTable, warehouseRows);
      });
    });
  }

  Future<void> upsertWarehouse(WarehousesTableCompanion row) {
    return into(warehousesTable).insertOnConflictUpdate(row);
  }

  Future<List<WarehousesTableData>> getWarehousesByCompany({
    required String organizationId,
    required String companyId,
    String? branchId,
  }) {
    return (select(warehousesTable)
          ..where((row) {
            final base =
                row.organizationId.equals(organizationId) &
                row.companyId.equals(companyId) &
                row.deletedAt.isNull();
            if (branchId == null || branchId.isEmpty) return base;
            return base &
                (row.branchId.equals(branchId) | row.branchId.isNull());
          })
          ..orderBy([
            (row) => OrderingTerm.asc(row.priority),
            (row) => OrderingTerm.asc(row.name),
          ]))
        .get();
  }

  Future<void> upsertVariantStockBalances({
    required List<VariantStockBalancesTableCompanion> rows,
  }) {
    return batch((batch) {
      batch.insertAllOnConflictUpdate(variantStockBalancesTable, rows);
    });
  }

  Future<List<VariantStockBalancesTableData>>
  getVariantStockBalancesByVariantIds({
    required String organizationId,
    required Set<String> variantIds,
  }) {
    if (variantIds.isEmpty) {
      return Future<List<VariantStockBalancesTableData>>.value(
        const <VariantStockBalancesTableData>[],
      );
    }
    return (select(variantStockBalancesTable)..where(
          (row) =>
              row.organizationId.equals(organizationId) &
              row.variantId.isIn(variantIds.toList(growable: false)),
        ))
        .get();
  }

  /// Replaces the full local Order set for [organizationId]/[companyId] with
  /// exactly [orderRows]/[itemRows] in a single transaction, mirroring
  /// [replaceCustomers]. Deleting matching rows from [OrdersTable] cascades
  /// to their item rows (`ON DELETE CASCADE`), so this method does not need
  /// to delete from [OrderItemsTable] directly.
  Future<void> replaceOrders({
    required String organizationId,
    required String companyId,
    required List<OrdersTableCompanion> orderRows,
    required List<OrderItemsTableCompanion> itemRows,
  }) {
    return transaction(() async {
      await (delete(ordersTable)..where(
            (row) =>
                row.organizationId.equals(organizationId) &
                row.companyId.equals(companyId),
          ))
          .go();

      await batch((batch) {
        batch.insertAll(ordersTable, orderRows);
        batch.insertAll(orderItemsTable, itemRows);
      });
    });
  }

  /// Inserts or updates exactly one Order row — the incremental-update
  /// primitive the future sync engine (EPIC-14) uses to keep the local cache
  /// fresh after the initial load, mirroring [upsertPriceList]. Callers must
  /// pair this with [replaceOrderItems] for the same order id so its item
  /// rows stay consistent with the new order row.
  Future<void> upsertOrder(OrdersTableCompanion row) {
    return into(ordersTable).insertOnConflictUpdate(row);
  }

  /// Replaces every item row for [orderId] with exactly [itemRows] in a
  /// single transaction — the sibling primitive to [upsertOrder] for an
  /// order's item list, since items are a full child collection rather than
  /// something upserted one row at a time from the client.
  Future<void> replaceOrderItems({
    required String orderId,
    required List<OrderItemsTableCompanion> itemRows,
  }) {
    return transaction(() async {
      await (delete(
        orderItemsTable,
      )..where((row) => row.orderId.equals(orderId))).go();

      await batch((batch) {
        batch.insertAll(orderItemsTable, itemRows);
      });
    });
  }

  /// Every non-soft-deleted Order currently stored locally for
  /// [organizationId]/[companyId], each paired with its ordered item rows.
  Future<List<OrderWithItemsRow>> getOrdersForCompany({
    required String organizationId,
    required String companyId,
  }) async {
    final orderRows =
        await (select(ordersTable)..where(
              (row) =>
                  row.organizationId.equals(organizationId) &
                  row.companyId.equals(companyId) &
                  row.deletedAt.isNull(),
            ))
            .get();

    final results = <OrderWithItemsRow>[];
    for (final orderRow in orderRows) {
      final itemRows =
          await (select(orderItemsTable)
                ..where((row) => row.orderId.equals(orderRow.id))
                ..orderBy([(row) => OrderingTerm.asc(row.position)]))
              .get();
      results.add(OrderWithItemsRow(order: orderRow, items: itemRows));
    }
    return results;
  }

  /// A single locally stored Order (with its ordered item rows) by [id],
  /// scoped to [organizationId]/[companyId], or null if not found/soft
  /// deleted.
  Future<OrderWithItemsRow?> getOrderById({
    required String organizationId,
    required String companyId,
    required String id,
  }) async {
    final orderRow =
        await (select(ordersTable)..where(
              (row) =>
                  row.organizationId.equals(organizationId) &
                  row.companyId.equals(companyId) &
                  row.id.equals(id) &
                  row.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    if (orderRow == null) return null;

    final itemRows =
        await (select(orderItemsTable)
              ..where((row) => row.orderId.equals(id))
              ..orderBy([(row) => OrderingTerm.asc(row.position)]))
            .get();
    return OrderWithItemsRow(order: orderRow, items: itemRows);
  }

  // ---------------------------------------------------------------------
  // TASK-106 — Colors ("cores", tasks.md seção 5.1)
  // ---------------------------------------------------------------------

  /// Replaces the full local Color palette for [organizationId] with exactly
  /// [colorRows] in a single transaction, mirroring [replacePriceLists].
  Future<void> replaceColors({
    required String organizationId,
    required List<ColorsTableCompanion> colorRows,
  }) {
    return transaction(() async {
      await (delete(
        colorsTable,
      )..where((row) => row.organizationId.equals(organizationId))).go();

      await batch((batch) {
        batch.insertAll(colorsTable, colorRows);
      });
    });
  }

  /// Inserts or updates exactly one Color row — the incremental-update
  /// primitive the future sync engine (EPIC-14) uses, mirroring
  /// [upsertPriceList].
  Future<void> upsertColor(ColorsTableCompanion row) {
    return into(colorsTable).insertOnConflictUpdate(row);
  }

  /// Every non-soft-deleted Color currently stored locally for
  /// [organizationId].
  Future<List<ColorsTableData>> getColorsForOrganization({
    required String organizationId,
  }) {
    return (select(colorsTable)..where(
          (row) =>
              row.organizationId.equals(organizationId) &
              row.deletedAt.isNull(),
        ))
        .get();
  }

  // ---------------------------------------------------------------------
  // TASK-106 — Size grids ("grades", tasks.md seção 5.1)
  // ---------------------------------------------------------------------

  /// Replaces the full local Size Grid template set for [organizationId]
  /// with exactly [sizeGridRows] in a single transaction, mirroring
  /// [replaceColors].
  Future<void> replaceSizeGrids({
    required String organizationId,
    required List<SizeGridsTableCompanion> sizeGridRows,
  }) {
    return transaction(() async {
      await (delete(
        sizeGridsTable,
      )..where((row) => row.organizationId.equals(organizationId))).go();

      await batch((batch) {
        batch.insertAll(sizeGridsTable, sizeGridRows);
      });
    });
  }

  /// Inserts or updates exactly one Size Grid template row.
  Future<void> upsertSizeGrid(SizeGridsTableCompanion row) {
    return into(sizeGridsTable).insertOnConflictUpdate(row);
  }

  /// Every non-soft-deleted Size Grid template currently stored locally for
  /// [organizationId].
  Future<List<SizeGridsTableData>> getSizeGridsForOrganization({
    required String organizationId,
  }) {
    return (select(sizeGridsTable)..where(
          (row) =>
              row.organizationId.equals(organizationId) &
              row.deletedAt.isNull(),
        ))
        .get();
  }

  // ---------------------------------------------------------------------
  // TASK-106 — Products & variants ("produtos"/"variantes", tasks.md
  // seção 5.1) — canonical offline cache, distinct from
  // [ProductSearchIndexTable] (TASK-069, search-only projection).
  // ---------------------------------------------------------------------

  /// Replaces the full local Product set for [organizationId]/[companyId]
  /// with exactly [productRows] in a single transaction, mirroring
  /// [replaceCustomers]. Deleting matching rows from [ProductsTable] cascades
  /// to their variant rows (`ON DELETE CASCADE`), so callers must re-supply
  /// every still-valid variant via [replaceProductVariants] for each product
  /// id in the same load.
  Future<void> replaceProducts({
    required String organizationId,
    String? companyId,
    required List<ProductsTableCompanion> productRows,
  }) {
    return transaction(() async {
      await (delete(productsTable)..where((row) {
            final base = row.organizationId.equals(organizationId);
            if (companyId == null) return base;
            return base & row.companyId.equals(companyId);
          }))
          .go();

      await batch((batch) {
        batch.insertAll(productsTable, productRows);
      });
    });
  }

  /// Inserts or updates exactly one Product row.
  Future<void> upsertProduct(ProductsTableCompanion row) {
    return into(productsTable).insertOnConflictUpdate(row);
  }

  /// Every non-soft-deleted Product currently stored locally for
  /// [organizationId]/[companyId].
  Future<List<ProductsTableData>> getProductsForCompany({
    required String organizationId,
    String? companyId,
  }) {
    return (select(productsTable)..where((row) {
          final base =
              row.organizationId.equals(organizationId) &
              row.deletedAt.isNull();
          if (companyId == null) return base;
          return base & row.companyId.equals(companyId);
        }))
        .get();
  }

  /// Replaces every variant row for [productId] with exactly [variantRows]
  /// in a single transaction — the sibling primitive to [replaceProducts]
  /// for a product's variant list, mirroring [replaceOrderItems].
  Future<void> replaceProductVariants({
    required String productId,
    required List<ProductVariantsTableCompanion> variantRows,
  }) {
    return transaction(() async {
      await (delete(
        productVariantsTable,
      )..where((row) => row.productId.equals(productId))).go();

      await batch((batch) {
        batch.insertAll(productVariantsTable, variantRows);
      });
    });
  }

  /// Inserts or updates exactly one Product Variant row.
  Future<void> upsertProductVariant(ProductVariantsTableCompanion row) {
    return into(productVariantsTable).insertOnConflictUpdate(row);
  }

  /// Every Variant currently stored locally for [productId] — there is no
  /// `deletedAt` filter here because `ProductVariant` has no tombstone field
  /// (see [ProductVariantsTable] docs); a discontinued variant is expressed
  /// through its `status` column instead.
  Future<List<ProductVariantsTableData>> getProductVariantsByProduct({
    required String productId,
  }) {
    return (select(
      productVariantsTable,
    )..where((row) => row.productId.equals(productId))).get();
  }

  // ---------------------------------------------------------------------
  // TASK-106 — Campaigns ("campanhas", tasks.md seção 5.1)
  // ---------------------------------------------------------------------

  /// Replaces the full local Campaign set for [organizationId]/[companyId]
  /// with exactly [campaignRows] in a single transaction, mirroring
  /// [replacePriceLists].
  Future<void> replaceCampaigns({
    required String organizationId,
    required String companyId,
    required List<CampaignsTableCompanion> campaignRows,
  }) {
    return transaction(() async {
      await (delete(campaignsTable)..where(
            (row) =>
                row.organizationId.equals(organizationId) &
                row.companyId.equals(companyId),
          ))
          .go();

      await batch((batch) {
        batch.insertAll(campaignsTable, campaignRows);
      });
    });
  }

  /// Inserts or updates exactly one Campaign row.
  Future<void> upsertCampaign(CampaignsTableCompanion row) {
    return into(campaignsTable).insertOnConflictUpdate(row);
  }

  /// Every non-soft-deleted Campaign currently stored locally for
  /// [organizationId]/[companyId].
  Future<List<CampaignsTableData>> getCampaignsForCompany({
    required String organizationId,
    required String companyId,
  }) {
    return (select(campaignsTable)..where(
          (row) =>
              row.organizationId.equals(organizationId) &
              row.companyId.equals(companyId) &
              row.deletedAt.isNull(),
        ))
        .get();
  }

  // ---------------------------------------------------------------------
  // TASK-106 — Targets ("metas", tasks.md seção 5.1) — structural
  // placeholder ahead of TASK-114's full Target domain model, see
  // [TargetsTable] docs.
  // ---------------------------------------------------------------------

  /// Replaces the full local Target set for [organizationId]/[companyId]
  /// with exactly [targetRows] in a single transaction, mirroring
  /// [replacePriceLists].
  Future<void> replaceTargets({
    required String organizationId,
    required String companyId,
    required List<TargetsTableCompanion> targetRows,
  }) {
    return transaction(() async {
      await (delete(targetsTable)..where(
            (row) =>
                row.organizationId.equals(organizationId) &
                row.companyId.equals(companyId),
          ))
          .go();

      await batch((batch) {
        batch.insertAll(targetsTable, targetRows);
      });
    });
  }

  /// Inserts or updates exactly one Target row.
  Future<void> upsertTarget(TargetsTableCompanion row) {
    return into(targetsTable).insertOnConflictUpdate(row);
  }

  /// Every non-soft-deleted Target currently stored locally for
  /// [organizationId]/[companyId].
  Future<List<TargetsTableData>> getTargetsForCompany({
    required String organizationId,
    required String companyId,
  }) {
    return (select(targetsTable)..where(
          (row) =>
              row.organizationId.equals(organizationId) &
              row.companyId.equals(companyId) &
              row.deletedAt.isNull(),
        ))
        .get();
  }

  // ---------------------------------------------------------------------
  // Offline package load status (TASK-107)
  // ---------------------------------------------------------------------

  /// Marks [entityKind] as incomplete for [organizationId]/[companyId] —
  /// `DownloadOfflinePackageUseCase` calls this immediately before it starts
  /// downloading that entity, so a crash, dropped connection or
  /// cancellation between this call and [markOfflinePackageEntityComplete]
  /// always leaves the entity flagged as not trustworthy, even though
  /// whatever that entity's table held from a previous successful load is
  /// left untouched.
  Future<void> markOfflinePackageEntityIncomplete({
    required String organizationId,
    required String companyId,
    required String entityKind,
    required DateTime now,
  }) {
    return into(offlinePackageLoadStatusTable).insertOnConflictUpdate(
      OfflinePackageLoadStatusTableCompanion.insert(
        organizationId: organizationId,
        companyId: companyId,
        entityKind: entityKind,
        isComplete: const Value(false),
        updatedAt: now,
      ),
    );
  }

  /// Marks [entityKind] as completed for [organizationId]/[companyId] after
  /// its local replace transaction has actually committed, recording
  /// [recordCount] and [now] as the last successful full load.
  Future<void> markOfflinePackageEntityComplete({
    required String organizationId,
    required String companyId,
    required String entityKind,
    required int recordCount,
    required DateTime now,
  }) {
    return into(offlinePackageLoadStatusTable).insertOnConflictUpdate(
      OfflinePackageLoadStatusTableCompanion.insert(
        organizationId: organizationId,
        companyId: companyId,
        entityKind: entityKind,
        isComplete: const Value(true),
        lastCompletedAt: Value(now),
        recordCount: Value(recordCount),
        updatedAt: now,
      ),
    );
  }

  /// Every offline package status row for [organizationId]/[companyId], one
  /// per entity that has ever started downloading.
  Future<List<OfflinePackageLoadStatusTableData>> getOfflinePackageStatuses({
    required String organizationId,
    required String companyId,
  }) {
    return (select(offlinePackageLoadStatusTable)..where(
          (row) =>
              row.organizationId.equals(organizationId) &
              row.companyId.equals(companyId),
        ))
        .get();
  }

  // ---------------------------------------------------------------------
  // Outbox (TASK-108, EPIC-14) — see [OutboxTable] docs.
  // ---------------------------------------------------------------------

  /// Enqueues a new `pending` Outbox operation identified by [id] (its
  /// `clientOperationId`), or returns the already-persisted row unchanged if
  /// [id] was already enqueued before — this is what makes `enqueue` safe to
  /// call more than once for the same logical operation (e.g. the app
  /// crashing/restarting right after this call, before the caller's own
  /// outer transaction — see below — is known to have committed).
  ///
  /// Runs inside its own [transaction], so the id lookup, the
  /// [sequenceNumber] computation and the insert always happen atomically
  /// relative to each other. Callers that need the enqueue and their own
  /// local write (e.g. persisting an order draft) to succeed or fail
  /// together must wrap both calls in one outer `database.transaction(...)`
  /// block themselves — Drift nests this inner transaction as a savepoint of
  /// that outer one rather than opening a second, independent transaction.
  Future<OutboxTableData> enqueueOutboxOperation({
    required String id,
    required String organizationId,
    String? companyId,
    required String entityType,
    required String entityId,
    required String operationType,
    required String payload,
    required DateTime createdAt,
    required String createdBy,
  }) {
    return transaction(() async {
      final existing = await (select(
        outboxTable,
      )..where((row) => row.id.equals(id))).getSingleOrNull();
      if (existing != null) return existing;

      final maxSequenceExpression = outboxTable.sequenceNumber.max();
      final maxSequenceQuery = selectOnly(outboxTable)
        ..addColumns([maxSequenceExpression]);
      final maxSequenceRow = await maxSequenceQuery.getSingle();
      final nextSequence =
          (maxSequenceRow.read(maxSequenceExpression) ?? 0) + 1;

      await into(outboxTable).insert(
        OutboxTableCompanion.insert(
          id: id,
          organizationId: organizationId,
          companyId: Value(companyId),
          entityType: entityType,
          entityId: entityId,
          operationType: operationType,
          payload: payload,
          status: const Value('pending'),
          attemptCount: const Value(0),
          createdAt: createdAt,
          createdBy: createdBy,
          sequenceNumber: nextSequence,
        ),
      );

      return (select(
        outboxTable,
      )..where((row) => row.id.equals(id))).getSingle();
    });
  }

  /// Moves the Outbox row [id] to `syncing`, bumping [attemptCount] and
  /// recording [attemptedAt] — a no-op if [id] no longer exists (e.g. it was
  /// already dropped after a confirmed sync elsewhere).
  Future<void> markOutboxSyncing({
    required String id,
    required DateTime attemptedAt,
  }) {
    return transaction(() async {
      final row = await (select(
        outboxTable,
      )..where((r) => r.id.equals(id))).getSingleOrNull();
      if (row == null) return;

      await (update(outboxTable)..where((r) => r.id.equals(id))).write(
        OutboxTableCompanion(
          status: const Value('syncing'),
          attemptCount: Value(row.attemptCount + 1),
          lastAttemptAt: Value(attemptedAt),
        ),
      );
    });
  }

  /// Moves the Outbox row [id] to `synced` — the sync engine (TASK-109)
  /// calls this only after the backend has confirmed the operation, never
  /// speculatively.
  Future<void> markOutboxSynced({required String id}) {
    return (update(outboxTable)..where((row) => row.id.equals(id))).write(
      const OutboxTableCompanion(status: Value('synced')),
    );
  }

  /// Moves the Outbox row [id] to `failed`, recording [error] and
  /// [attemptedAt] — the row is kept, never removed, so the retry policy
  /// (TASK-109) and failure UI (TASK-112) can act on it.
  Future<void> markOutboxFailed({
    required String id,
    required String error,
    required DateTime attemptedAt,
  }) {
    return (update(outboxTable)..where((row) => row.id.equals(id))).write(
      OutboxTableCompanion(
        status: const Value('failed'),
        lastError: Value(error),
        lastAttemptAt: Value(attemptedAt),
      ),
    );
  }

  /// Moves the Outbox row [id] to `conflict`, recording [error] and
  /// [attemptedAt] — reserved for a remote rejection that requires manual
  /// resolution (TASK-110/TASK-112) rather than a plain retry.
  Future<void> markOutboxConflict({
    required String id,
    required String error,
    required DateTime attemptedAt,
  }) {
    return (update(outboxTable)..where((row) => row.id.equals(id))).write(
      OutboxTableCompanion(
        status: const Value('conflict'),
        lastError: Value(error),
        lastAttemptAt: Value(attemptedAt),
      ),
    );
  }

  /// A single Outbox row by [id], or `null` if it no longer exists.
  Future<OutboxTableData?> getOutboxOperationById(String id) {
    return (select(
      outboxTable,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
  }

  /// Every Outbox row for [organizationId] whose `status` is one of
  /// [statuses], oldest-enqueued first ([OutboxTable.sequenceNumber]) — the
  /// order the sync engine (TASK-109) must process them in.
  Future<List<OutboxTableData>> getOutboxOperationsByStatus({
    required String organizationId,
    required List<String> statuses,
  }) {
    return (select(outboxTable)
          ..where(
            (row) =>
                row.organizationId.equals(organizationId) &
                row.status.isIn(statuses),
          )
          ..orderBy([(row) => OrderingTerm.asc(row.sequenceNumber)]))
        .get();
  }

  /// Every Outbox row for [organizationId]/[entityType]/[entityId], oldest
  /// first — every operation ever enqueued for one specific entity, in the
  /// exact order they must be replayed (e.g. never an `update` before the
  /// `create` it depends on).
  Future<List<OutboxTableData>> getOutboxOperationsByEntity({
    required String organizationId,
    required String entityType,
    required String entityId,
  }) {
    return (select(outboxTable)
          ..where(
            (row) =>
                row.organizationId.equals(organizationId) &
                row.entityType.equals(entityType) &
                row.entityId.equals(entityId),
          )
          ..orderBy([(row) => OrderingTerm.asc(row.sequenceNumber)]))
        .get();
  }

  /// Reactive count of Outbox rows per status for [organizationId] — what
  /// the Central de Sincronização (TASK-112) watches to show pending/failed
  /// work in real time, re-emitting on every local Outbox write in scope,
  /// mirroring [watchFavoriteProductIds].
  Stream<OutboxStatusCounts> watchOutboxStatusCounts({
    required String organizationId,
  }) {
    final query = select(outboxTable)
      ..where((row) => row.organizationId.equals(organizationId));
    return query.watch().map((rows) {
      var pending = 0;
      var syncing = 0;
      var failed = 0;
      var conflict = 0;
      for (final row in rows) {
        switch (row.status) {
          case 'pending':
            pending++;
          case 'syncing':
            syncing++;
          case 'failed':
            failed++;
          case 'conflict':
            conflict++;
        }
      }
      return OutboxStatusCounts(
        pending: pending,
        syncing: syncing,
        failed: failed,
        conflict: conflict,
      );
    });
  }

  // ---------------------------------------------------------------------
  // Sync cursors (TASK-109, EPIC-14) — see [SyncCursorsTable] docs.
  // ---------------------------------------------------------------------

  /// Inserts or updates the incremental pull bookmark for
  /// [organizationId]/[companyId]/[entityKind] — `SyncEngine.runPull` calls
  /// this only after successfully applying every non-skipped record of a
  /// page, never speculatively before.
  Future<void> upsertSyncCursor({
    required String organizationId,
    required String companyId,
    required String entityKind,
    required String? cursorValue,
    required DateTime updatedAt,
  }) {
    return into(syncCursorsTable).insertOnConflictUpdate(
      SyncCursorsTableCompanion.insert(
        organizationId: organizationId,
        companyId: companyId,
        entityKind: entityKind,
        cursorValue: Value(cursorValue),
        updatedAt: updatedAt,
      ),
    );
  }

  /// The current incremental pull bookmark for
  /// [organizationId]/[companyId]/[entityKind], or `null` if this entity has
  /// never been pulled incrementally yet for that scope.
  Future<SyncCursorsTableData?> getSyncCursor({
    required String organizationId,
    required String companyId,
    required String entityKind,
  }) {
    return (select(syncCursorsTable)..where(
          (row) =>
              row.organizationId.equals(organizationId) &
              row.companyId.equals(companyId) &
              row.entityKind.equals(entityKind),
        ))
        .getSingleOrNull();
  }

  // ---------------------------------------------------------------------
  // Conflict resolution (TASK-110, EPIC-14) — see [ConflictRecordsTable]/
  // [ConflictAuditLogTable] docs.
  // ---------------------------------------------------------------------

  /// Persists a new conflict record, or returns the already-open
  /// (`status == 'conflict'`) one for the same [outboxOperationId] unchanged
  /// if one already exists — idempotent against
  /// `ConflictResolutionService.resolve` being called again for an entity
  /// whose Outbox operation is already blocked, so a repeated sync attempt
  /// on an unresolved conflict never creates a second, duplicate record for
  /// it.
  Future<ConflictRecordsTableData> insertConflictRecord({
    required String id,
    required String organizationId,
    String? companyId,
    required String entityType,
    required String entityId,
    required String outboxOperationId,
    required String policy,
    required String localSnapshot,
    required String remoteSnapshot,
    required String conflictingFields,
    required DateTime detectedAt,
  }) {
    return transaction(() async {
      final existing =
          await (select(conflictRecordsTable)..where(
                (row) =>
                    row.outboxOperationId.equals(outboxOperationId) &
                    row.status.equals('conflict'),
              ))
              .getSingleOrNull();
      if (existing != null) return existing;

      await into(conflictRecordsTable).insert(
        ConflictRecordsTableCompanion.insert(
          id: id,
          organizationId: organizationId,
          companyId: Value(companyId),
          entityType: entityType,
          entityId: entityId,
          outboxOperationId: outboxOperationId,
          policy: policy,
          localSnapshot: localSnapshot,
          remoteSnapshot: remoteSnapshot,
          conflictingFields: conflictingFields,
          status: const Value('conflict'),
          detectedAt: detectedAt,
        ),
      );

      return (select(
        conflictRecordsTable,
      )..where((row) => row.id.equals(id))).getSingle();
    });
  }

  /// Every open (`status == 'conflict'`) record for [organizationId],
  /// oldest-detected first — the priority order TASK-111's list screen
  /// consumes them in.
  Future<List<ConflictRecordsTableData>> getOpenConflictRecords({
    required String organizationId,
  }) {
    return (select(conflictRecordsTable)
          ..where(
            (row) =>
                row.organizationId.equals(organizationId) &
                row.status.equals('conflict'),
          )
          ..orderBy([(row) => OrderingTerm.asc(row.detectedAt)]))
        .get();
  }

  /// A single conflict record by [id], or `null` if it does not exist.
  Future<ConflictRecordsTableData?> getConflictRecordById(String id) {
    return (select(
      conflictRecordsTable,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
  }

  /// Appends a new conflict resolution audit entry — never updated/removed
  /// afterwards, same "permanent history" rule as the centralized
  /// `AuditLogEntry`.
  Future<ConflictAuditLogTableData> insertConflictAuditEntry({
    required String id,
    required String organizationId,
    String? companyId,
    required String entityType,
    required String entityId,
    required String policy,
    required String outcome,
    required String actor,
    required DateTime performedAt,
    required String discardedFields,
    required String conflictingFields,
    String? conflictRecordId,
  }) async {
    await into(conflictAuditLogTable).insert(
      ConflictAuditLogTableCompanion.insert(
        id: id,
        organizationId: organizationId,
        companyId: Value(companyId),
        entityType: entityType,
        entityId: entityId,
        policy: policy,
        outcome: outcome,
        actor: actor,
        performedAt: performedAt,
        discardedFields: Value(discardedFields),
        conflictingFields: Value(conflictingFields),
        conflictRecordId: Value(conflictRecordId),
      ),
    );
    return (select(
      conflictAuditLogTable,
    )..where((row) => row.id.equals(id))).getSingle();
  }

  /// Every conflict resolution audit entry for [organizationId], most
  /// recent first.
  Future<List<ConflictAuditLogTableData>> getConflictAuditLog({
    required String organizationId,
  }) {
    return (select(conflictAuditLogTable)
          ..where((row) => row.organizationId.equals(organizationId))
          ..orderBy([(row) => OrderingTerm.desc(row.performedAt)]))
        .get();
  }
}

/// Result row of [AppDatabase.watchOutboxStatusCounts] — how many
/// [OutboxTable] rows for a scope currently sit in each non-terminal status
/// (`synced` rows are intentionally not counted here, they are not "work").
class OutboxStatusCounts {
  const OutboxStatusCounts({
    required this.pending,
    required this.syncing,
    required this.failed,
    required this.conflict,
  });

  final int pending;
  final int syncing;
  final int failed;
  final int conflict;
}
