import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/inventory/inventory.dart';

void main() {
  group('VariantStockBalanceMapper', () {
    const mapper = VariantStockBalanceMapper();

    test('maps dto to entity and computes sellable quantity', () {
      final dto = VariantStockBalanceDto(
        id: 'variant-1_wh-1',
        organizationId: 'org-1',
        companyId: 'company-1',
        productId: 'product-1',
        variantId: 'variant-1',
        warehouseId: 'wh-1',
        physicalQuantity: 12,
        reservedQuantity: 3,
        blockedQuantity: 2,
        updatedAt: DateTime.utc(2026, 8, 27),
        updatedBy: 'owner-1',
        lastSource: 'manual_adjustment',
        version: 1,
      );

      final entity = mapper.toEntity(
        dto,
        cacheFetchedAt: DateTime.utc(2026, 8, 27, 12),
      );

      expect(entity.variantId, 'variant-1');
      expect(entity.productId, 'product-1');
      expect(entity.sellableQuantity, 7);
      expect(entity.cacheFetchedAt, DateTime.utc(2026, 8, 27, 12));
    });
  });
}
