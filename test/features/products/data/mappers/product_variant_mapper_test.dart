import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/products/data/dtos/product_variant_dto.dart';
import 'package:vestipro/features/products/data/mappers/product_variant_mapper.dart';
import 'package:vestipro/features/products/products.dart';

void main() {
  group('ProductVariantMapper', () {
    const mapper = ProductVariantMapper();

    test('round-trips a variant with its own EAN', () {
      final now = DateTime.utc(2026, 1, 1);
      final entity = ProductVariant(
        id: 'variant-1',
        organizationId: 'org-1',
        productId: 'product-1',
        colorId: 'color-preto',
        sizeGridTemplateId: 'grid-pp-m',
        sizeId: 'size-p',
        sku: Sku.parse('CAMISA-001-PRETO-P'),
        ean: Ean.parse('4006381333931'),
        status: ProductVariantStatus.active,
        createdAt: now,
        createdBy: 'user-1',
        updatedAt: now,
        updatedBy: 'user-1',
        version: 1,
        syncStatus: ProductSyncStatus.pending,
      );

      final dto = mapper.toDto(entity);
      final json = dto.toJson();
      expect(json['ean'], '4006381333931');
      expect(json['createdAt'], isA<Timestamp>());

      final parsed = mapper.toEntity(
        ProductVariantDto.fromJson(json, id: entity.id),
      );
      expect(parsed.id, entity.id);
      expect(parsed.sku, entity.sku);
      expect(parsed.ean, entity.ean);
      expect(parsed.status, ProductVariantStatus.active);
      expect(parsed.syncStatus, ProductSyncStatus.pending);
    });
  });
}
