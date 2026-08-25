import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/products/data/repositories/shared_preferences_product_variant_repository.dart';
import 'package:vestipro/features/products/products.dart';

void main() {
  group('ProductVariant use cases', () {
    late SharedPreferencesProductVariantRepository repository;
    late UpdateProductVariantUseCase update;
    late DeleteProductVariantUseCase delete;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      repository = const SharedPreferencesProductVariantRepository();
      update = UpdateProductVariantUseCase(repository);
      delete = DeleteProductVariantUseCase(repository);
    });

    test(
      'enforces active SKU and EAN uniqueness inside organization',
      () async {
        await repository.create(
          variant: _variant(
            id: 'variant-1',
            sku: 'CAMISA-001-PRETO-P',
            ean: '4006381333931',
          ),
        );
        await repository.create(
          variant: _variant(id: 'variant-2', sku: 'CAMISA-001-PRETO-M'),
        );

        final skuConflict = await update(
          organizationId: 'org-1',
          id: 'variant-2',
          sku: 'CAMISA-001-PRETO-P',
          updatedBy: 'user-2',
        );
        expect(
          (skuConflict as AppFailure<ProductVariant>).failure,
          isA<ConflictFailure>().having(
            (failure) => failure.code,
            'code',
            'product_variant_sku_already_exists',
          ),
        );

        final eanConflict = await update(
          organizationId: 'org-1',
          id: 'variant-2',
          sku: 'CAMISA-001-PRETO-M',
          ean: '4006381333931',
          updatedBy: 'user-2',
        );
        expect(
          (eanConflict as AppFailure<ProductVariant>).failure,
          isA<ConflictFailure>().having(
            (failure) => failure.code,
            'code',
            'product_variant_ean_already_exists',
          ),
        );
      },
    );

    test('delete request inactivates an order-referenced variant', () async {
      await repository.create(
        variant: _variant(id: 'variant-1', sku: 'CAMISA-001-PRETO-P'),
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('order_variant_usage_org-1', <String>[
        'variant-1',
      ]);

      final result = await delete(
        organizationId: 'org-1',
        id: 'variant-1',
        deletedBy: 'user-2',
      );

      final inactive = (result as AppSuccess<ProductVariant>).value;
      expect(inactive.status, ProductVariantStatus.inactive);
      final persisted = await repository.getById(
        organizationId: 'org-1',
        id: 'variant-1',
      );
      expect(
        (persisted as AppSuccess<ProductVariant>).value.status,
        ProductVariantStatus.inactive,
      );
    });
  });
}

ProductVariant _variant({
  required String id,
  required String sku,
  String? ean,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return ProductVariant(
    id: id,
    organizationId: 'org-1',
    productId: 'product-1',
    colorId: 'color-preto',
    sizeGridTemplateId: 'grid-pp-m',
    sizeId: 'size-p',
    sku: Sku.parse(sku),
    ean: ean == null ? null : Ean.parse(ean),
    status: ProductVariantStatus.active,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: ProductSyncStatus.synced,
  );
}
