import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/inventory/inventory.dart';

void main() {
  group('WarehouseMapper', () {
    const mapper = WarehouseMapper();

    test('round-trips a warehouse with nullable branchId', () {
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

      final dto = mapper.toDto(warehouse);
      final parsed = mapper.toEntity(
        WarehouseDto.fromJson(dto.toJson(), id: dto.id),
      );

      expect(parsed.id, warehouse.id);
      expect(parsed.branchId, isNull);
      expect(parsed.type, WarehouseType.distributionCenter);
      expect(parsed.syncStatus, 'synced');
    });
  });
}
