import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/database/database.dart';

/// No-op [QueryExecutorUser] used only to seed a raw "schema version 12"
/// sqlite file directly through the executor, bypassing `AppDatabase`'s own
/// `onCreate`/`onUpgrade` machinery entirely — the seed step must not create
/// any of the tables `AppDatabase` itself would create, so the later,
/// real `AppDatabase(schemaVersion: 13)` open exercises a genuine
/// `onUpgrade(from: 12, to: 13)` migration.
class _RawSchemaVersionSeed implements QueryExecutorUser {
  const _RawSchemaVersionSeed(this.schemaVersion);

  @override
  final int schemaVersion;

  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) =>
      Future<void>.value();
}

void main() {
  group('AppDatabase schema (TASK-106)', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test('creates every TASK-106 offline-load table with the current schema '
        'version', () async {
      expect(database.schemaVersion, 19);
      await database.customStatement('SELECT 1');

      final tableNames = await database
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name NOT LIKE 'sqlite_%'",
          )
          .map((row) => row.read<String>('name'))
          .get();

      expect(
        tableNames,
        containsAll(<String>[
          'customers',
          'customer_addresses',
          'customer_contacts',
          'product_search_index',
          'favorites',
          'price_lists',
          'price_list_items',
          'payment_terms',
          'warehouses',
          'variant_stock_balances',
          'orders',
          'order_items',
          'colors',
          'size_grids',
          'products',
          'product_variants',
          'campaigns',
          'targets',
        ]),
      );
    });

    test('product_variants columns match the ProductVariant domain shape '
        '(id, organizationId, productId FK, colorId, sizeGridTemplateId, '
        'sizeId, sku, status, sync columns)', () async {
      await database.customStatement('SELECT 1');

      final columnNames = await database
          .customSelect("PRAGMA table_info('product_variants')")
          .map((row) => row.read<String>('name'))
          .get();

      expect(
        columnNames,
        containsAll(<String>[
          'id',
          'organization_id',
          'product_id',
          'color_id',
          'size_grid_template_id',
          'size_id',
          'sku',
          'status',
          'version',
          'sync_status',
        ]),
      );
    });

    test(
      'isolates Products/Colors/Campaigns/Targets rows by organizationId '
      '(+companyId when applicable) — no cross-tenant leakage locally',
      () async {
        final now = DateTime.utc(2026, 8, 31);

        await database.replaceColors(
          organizationId: 'org-1',
          colorRows: <ColorsTableCompanion>[
            _colorRow(id: 'color-org-1', organizationId: 'org-1', now: now),
          ],
        );
        await database.replaceColors(
          organizationId: 'org-2',
          colorRows: <ColorsTableCompanion>[
            _colorRow(id: 'color-org-2', organizationId: 'org-2', now: now),
          ],
        );

        final org1Colors = await database.getColorsForOrganization(
          organizationId: 'org-1',
        );
        final org2Colors = await database.getColorsForOrganization(
          organizationId: 'org-2',
        );

        expect(org1Colors.map((row) => row.id), <String>['color-org-1']);
        expect(org2Colors.map((row) => row.id), <String>['color-org-2']);

        await database.replaceCampaigns(
          organizationId: 'org-1',
          companyId: 'company-1',
          campaignRows: <CampaignsTableCompanion>[
            _campaignRow(
              id: 'campaign-1',
              organizationId: 'org-1',
              companyId: 'company-1',
              now: now,
            ),
          ],
        );
        await database.replaceCampaigns(
          organizationId: 'org-1',
          companyId: 'company-2',
          campaignRows: <CampaignsTableCompanion>[
            _campaignRow(
              id: 'campaign-2',
              organizationId: 'org-1',
              companyId: 'company-2',
              now: now,
            ),
          ],
        );

        final company1Campaigns = await database.getCampaignsForCompany(
          organizationId: 'org-1',
          companyId: 'company-1',
        );
        expect(company1Campaigns.map((row) => row.id), <String>['campaign-1']);
      },
    );

    test('soft delete: a Color/Product with deletedAt set is excluded from '
        'active queries but stays physically in the local database', () async {
      final now = DateTime.utc(2026, 8, 31);

      await database.replaceColors(
        organizationId: 'org-1',
        colorRows: <ColorsTableCompanion>[
          _colorRow(id: 'color-active', organizationId: 'org-1', now: now),
          _colorRow(
            id: 'color-deleted',
            organizationId: 'org-1',
            now: now,
            deletedAt: now,
          ),
        ],
      );

      final activeColors = await database.getColorsForOrganization(
        organizationId: 'org-1',
      );
      expect(activeColors.map((row) => row.id), <String>['color-active']);

      final allRowsInTable = await database.select(database.colorsTable).get();
      expect(allRowsInTable.map((row) => row.id).toSet(), <String>{
        'color-active',
        'color-deleted',
      });

      await database.upsertProduct(
        _productRow(
          id: 'product-active',
          organizationId: 'org-1',
          companyId: 'company-1',
          now: now,
        ),
      );
      await database.upsertProduct(
        _productRow(
          id: 'product-deleted',
          organizationId: 'org-1',
          companyId: 'company-1',
          now: now,
          deletedAt: now,
        ),
      );

      final activeProducts = await database.getProductsForCompany(
        organizationId: 'org-1',
        companyId: 'company-1',
      );
      expect(activeProducts.map((row) => row.id), <String>['product-active']);

      final allProductRows = await database
          .select(database.productsTable)
          .get();
      expect(allProductRows.map((row) => row.id).toSet(), <String>{
        'product-active',
        'product-deleted',
      });
    });

    test(
      'cascades product deletion to its variant rows, scoped to org/company',
      () async {
        final now = DateTime.utc(2026, 8, 31);

        await database.replaceProducts(
          organizationId: 'org-1',
          companyId: 'company-1',
          productRows: <ProductsTableCompanion>[
            _productRow(
              id: 'product-1',
              organizationId: 'org-1',
              companyId: 'company-1',
              now: now,
            ),
          ],
        );
        await database.replaceProductVariants(
          productId: 'product-1',
          variantRows: <ProductVariantsTableCompanion>[
            _variantRow(
              id: 'variant-1',
              organizationId: 'org-1',
              productId: 'product-1',
              now: now,
            ),
          ],
        );

        final variantsBefore = await database.getProductVariantsByProduct(
          productId: 'product-1',
        );
        expect(variantsBefore, hasLength(1));

        // A full reload for the same org/company with an empty product set
        // must remove the previous product row and, via `ON DELETE CASCADE`,
        // its variant rows too.
        await database.replaceProducts(
          organizationId: 'org-1',
          companyId: 'company-1',
          productRows: const <ProductsTableCompanion>[],
        );

        final variantsAfter = await database.getProductVariantsByProduct(
          productId: 'product-1',
        );
        expect(variantsAfter, isEmpty);
      },
    );

    test('upgrades an existing schema version 12 database to 13 preserving '
        'pre-existing local data and adding every TASK-106 table', () async {
      final seedFile = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}'
        'vestipro_task106_migration_${DateTime.now().microsecondsSinceEpoch}.sqlite',
      );
      addTearDown(() async {
        if (seedFile.existsSync()) seedFile.deleteSync();
      });

      // 1. Seed a raw "schema version 12" database with one pre-existing
      // table/row, entirely bypassing `AppDatabase`'s own migration
      // machinery (see `_RawSchemaVersionSeed`).
      final seedExecutor = NativeDatabase(seedFile);
      await seedExecutor.ensureOpen(const _RawSchemaVersionSeed(12));
      await seedExecutor.runCustom(
        'CREATE TABLE legacy_probe (id TEXT NOT NULL PRIMARY KEY, '
        'organization_id TEXT NOT NULL)',
      );
      await seedExecutor.runInsert(
        'INSERT INTO legacy_probe (id, organization_id) VALUES (?, ?)',
        <Object?>['legacy-1', 'org-1'],
      );
      await seedExecutor.close();

      // 2. Open the real `AppDatabase` (schemaVersion 13) against that
      // same file — this must run the real `onUpgrade(from: 12, to: 13)`
      // migration, which only creates the TASK-106 tables (every earlier
      // `if (from < N)` branch is skipped because `from` is already 12).
      final upgradedDatabase = AppDatabase(NativeDatabase(seedFile));
      addTearDown(() => upgradedDatabase.close());

      final preservedRows = await upgradedDatabase
          .customSelect('SELECT id, organization_id FROM legacy_probe')
          .map(
            (row) => (
              id: row.read<String>('id'),
              organizationId: row.read<String>('organization_id'),
            ),
          )
          .get();
      expect(preservedRows, hasLength(1));
      expect(preservedRows.single.id, 'legacy-1');
      expect(preservedRows.single.organizationId, 'org-1');

      final tableNames = await upgradedDatabase
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name NOT LIKE 'sqlite_%'",
          )
          .map((row) => row.read<String>('name'))
          .get();
      expect(
        tableNames,
        containsAll(<String>[
          'legacy_probe',
          'colors',
          'size_grids',
          'products',
          'product_variants',
          'campaigns',
          'targets',
        ]),
      );

      // The newly created tables must be immediately usable through the
      // same typed helpers as a fresh database.
      await upgradedDatabase.replaceColors(
        organizationId: 'org-1',
        colorRows: <ColorsTableCompanion>[
          _colorRow(
            id: 'color-1',
            organizationId: 'org-1',
            now: DateTime.utc(2026, 8, 31),
          ),
        ],
      );
      final colors = await upgradedDatabase.getColorsForOrganization(
        organizationId: 'org-1',
      );
      expect(colors.map((row) => row.id), <String>['color-1']);
    });
  });
}

ColorsTableCompanion _colorRow({
  required String id,
  required String organizationId,
  required DateTime now,
  DateTime? deletedAt,
}) {
  return ColorsTableCompanion.insert(
    id: id,
    organizationId: organizationId,
    code: 'COD-$id',
    name: 'Cor $id',
    hex: '#000000',
    createdAt: now,
    createdBy: 'owner-1',
    updatedAt: now,
    updatedBy: 'owner-1',
    deletedAt: Value(deletedAt),
    status: 'available',
    version: 1,
    syncStatus: 'synced',
  );
}

ProductsTableCompanion _productRow({
  required String id,
  required String organizationId,
  required String companyId,
  required DateTime now,
  DateTime? deletedAt,
}) {
  return ProductsTableCompanion.insert(
    id: id,
    organizationId: organizationId,
    companyId: Value(companyId),
    sku: 'SKU-$id',
    reference: 'REF-$id',
    name: 'Produto $id',
    status: 'active',
    createdAt: now,
    createdBy: 'owner-1',
    updatedAt: now,
    updatedBy: 'owner-1',
    deletedAt: Value(deletedAt),
    version: 1,
    syncStatus: 'synced',
  );
}

ProductVariantsTableCompanion _variantRow({
  required String id,
  required String organizationId,
  required String productId,
  required DateTime now,
}) {
  return ProductVariantsTableCompanion.insert(
    id: id,
    organizationId: organizationId,
    productId: productId,
    colorId: 'color-1',
    sizeGridTemplateId: 'size-grid-1',
    sizeId: 'size-1',
    sku: 'SKU-$id',
    status: 'active',
    createdAt: now,
    createdBy: 'owner-1',
    updatedAt: now,
    updatedBy: 'owner-1',
    version: 1,
    syncStatus: 'synced',
  );
}

CampaignsTableCompanion _campaignRow({
  required String id,
  required String organizationId,
  required String companyId,
  required DateTime now,
}) {
  return CampaignsTableCompanion.insert(
    id: id,
    organizationId: organizationId,
    companyId: companyId,
    name: 'Campanha $id',
    validFrom: now,
    validTo: now.add(const Duration(days: 30)),
    customerSegment: 'varejo',
    discountType: 'percentage',
    discountValue: 10,
    stackableWithOtherCampaigns: false,
    createdAt: now,
    createdBy: 'owner-1',
    updatedAt: now,
    updatedBy: 'owner-1',
    status: 'active',
    version: 1,
    syncStatus: 'synced',
  );
}
