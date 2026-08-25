import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/products/data/repositories/shared_preferences_product_variant_repository.dart';
import 'package:vestipro/features/products/products.dart';

void main() {
  group('ListProductVariantsByProductUseCase', () {
    late SharedPreferencesProductVariantRepository repository;
    late ListProductVariantsByProductUseCase useCase;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      repository = const SharedPreferencesProductVariantRepository();
      useCase = ListProductVariantsByProductUseCase(repository);
      await repository.create(
        variant: _variant(id: 'variant-1', productId: 'product-1'),
      );
      await repository.create(
        variant: _variant(id: 'variant-2', productId: 'product-1'),
      );
      await repository.create(
        variant: _variant(id: 'variant-3', productId: 'product-2'),
      );
    });

    test('lists only variants of the requested product', () async {
      final result = await useCase(
        organizationId: 'org-1',
        productId: 'product-1',
      );

      expect(result, isA<AppSuccess<List<ProductVariant>>>());
      final variants = (result as AppSuccess<List<ProductVariant>>).value;
      expect(variants.map((variant) => variant.id).toSet(), <String>{
        'variant-1',
        'variant-2',
      });
    });

    test('returns an empty list for a product with no variants', () async {
      final result = await useCase(
        organizationId: 'org-1',
        productId: 'product-without-variants',
      );

      expect((result as AppSuccess<List<ProductVariant>>).value, isEmpty);
    });

    test('trims organizationId and productId before querying', () async {
      final result = await useCase(
        organizationId: '  org-1  ',
        productId: '  product-1  ',
      );

      expect((result as AppSuccess<List<ProductVariant>>).value.length, 2);
    });
  });
}

ProductVariant _variant({required String id, required String productId}) {
  final now = DateTime.utc(2026, 1, 1);
  return ProductVariant(
    id: id,
    organizationId: 'org-1',
    productId: productId,
    colorId: 'color-1',
    sizeGridTemplateId: 'grid-1',
    sizeId: 'size-1',
    sku: Sku.parse('SKU-$id'),
    status: ProductVariantStatus.active,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: ProductSyncStatus.synced,
  );
}
