import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/database/database.dart';

void main() {
  group('AppDatabase warehouses migration', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test('creates warehouses table in schema version 8', () async {
      expect(database.schemaVersion, 9);
      await database.customStatement('SELECT 1');

      final tableNames = await database
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name NOT LIKE 'sqlite_%'",
          )
          .map((row) => row.read<String>('name'))
          .get();

      expect(tableNames, contains('warehouses'));
    });

    test('filters by branch while preserving centralized warehouses', () async {
      final now = DateTime.utc(2026, 8, 27);
      await database.replaceWarehouses(
        organizationId: 'org-1',
        companyId: 'company-1',
        warehouseRows: <WarehousesTableCompanion>[
          WarehousesTableCompanion.insert(
            id: 'central',
            organizationId: 'org-1',
            companyId: 'company-1',
            branchId: const Value(null),
            code: 'CD-01',
            name: 'Central',
            type: 'distributionCenter',
            isActive: true,
            priority: const Value(0),
            createdAt: now,
            createdBy: 'owner-1',
            updatedAt: now,
            updatedBy: 'owner-1',
            deletedAt: const Value(null),
            version: 1,
            syncStatus: 'synced',
          ),
          WarehousesTableCompanion.insert(
            id: 'branch',
            organizationId: 'org-1',
            companyId: 'company-1',
            branchId: const Value('branch-1'),
            code: 'LOJA-01',
            name: 'Loja',
            type: 'store',
            isActive: true,
            priority: const Value(1),
            createdAt: now,
            createdBy: 'owner-1',
            updatedAt: now,
            updatedBy: 'owner-1',
            deletedAt: const Value(null),
            version: 1,
            syncStatus: 'synced',
          ),
        ],
      );

      final rows = await database.getWarehousesByCompany(
        organizationId: 'org-1',
        companyId: 'company-1',
        branchId: 'branch-1',
      );

      expect(rows.map((row) => row.id).toList(), <String>['central', 'branch']);
    });
  });
}
