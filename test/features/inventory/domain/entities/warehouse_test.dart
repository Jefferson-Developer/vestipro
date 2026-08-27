import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/inventory/inventory.dart';

void main() {
  group('Warehouse', () {
    test('supports centralized warehouses with nullable branchId', () {
      final warehouse = Warehouse(
        id: 'wh-1',
        organizationId: 'org-1',
        companyId: 'company-1',
        branchId: null,
        code: 'CD-01',
        name: 'Centro de Distribuicao',
        type: WarehouseType.distributionCenter,
        isActive: true,
        priority: 1,
        createdAt: DateTime.utc(2026, 8, 27),
        createdBy: 'owner-1',
        updatedAt: DateTime.utc(2026, 8, 27),
        updatedBy: 'owner-1',
        version: 1,
        syncStatus: 'synced',
      );

      expect(warehouse.branchId, isNull);
      expect(warehouse.isDeleted, isFalse);
      expect(warehouse.type, WarehouseType.distributionCenter);
    });

    test(
      'copyWith can deactivate and soft-delete without changing identity',
      () {
        final warehouse = Warehouse(
          id: 'wh-1',
          organizationId: 'org-1',
          companyId: 'company-1',
          branchId: 'branch-1',
          code: 'LOJA-01',
          name: 'Loja Centro',
          type: WarehouseType.store,
          isActive: true,
          priority: 3,
          createdAt: DateTime.utc(2026, 8, 27),
          createdBy: 'owner-1',
          updatedAt: DateTime.utc(2026, 8, 27),
          updatedBy: 'owner-1',
          version: 1,
          syncStatus: 'synced',
        );

        final updated = warehouse.copyWith(
          isActive: false,
          deletedAt: DateTime.utc(2026, 8, 28),
          updatedBy: 'admin-1',
          version: 2,
        );

        expect(updated.id, warehouse.id);
        expect(updated.companyId, warehouse.companyId);
        expect(updated.isActive, isFalse);
        expect(updated.deletedAt, DateTime.utc(2026, 8, 28));
        expect(updated.version, 2);
      },
    );
  });
}
