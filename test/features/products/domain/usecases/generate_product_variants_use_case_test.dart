import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/products/data/repositories/shared_preferences_product_color_repository.dart';
import 'package:vestipro/features/products/data/repositories/shared_preferences_product_variant_repository.dart';
import 'package:vestipro/features/products/data/repositories/shared_preferences_size_grid_template_repository.dart';
import 'package:vestipro/features/products/products.dart';

import '../../product_factory.dart';

void main() {
  group('GenerateProductVariantsUseCase', () {
    late _InMemoryProductRepository productRepository;
    late SharedPreferencesProductColorRepository colorRepository;
    late SharedPreferencesSizeGridTemplateRepository sizeGridRepository;
    late SharedPreferencesProductVariantRepository variantRepository;
    late GenerateProductVariantsUseCase generate;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      productRepository = _InMemoryProductRepository();
      colorRepository = const SharedPreferencesProductColorRepository();
      sizeGridRepository = const SharedPreferencesSizeGridTemplateRepository();
      variantRepository = const SharedPreferencesProductVariantRepository();
      generate = GenerateProductVariantsUseCase(
        productRepository,
        colorRepository,
        sizeGridRepository,
        variantRepository,
      );

      await colorRepository.create(color: _color('color-preto', 'PRETO'));
      await colorRepository.create(color: _color('color-branco', 'BRANCO'));
      await _createTemplate(
        sizeGridRepository,
        id: 'grid-pp-m',
        labels: const <String>['PP', 'P', 'M'],
      );
      productRepository.products.add(
        buildTestProduct(
          colorIds: const <String>['color-preto', 'color-branco'],
          sizeGridTemplateId: 'grid-pp-m',
        ),
      );
    });

    test(
      'generates every color by size combination for a new product',
      () async {
        final result = await generate(
          organizationId: 'org-1',
          productId: 'product-1',
          generatedBy: 'user-1',
        );

        final variants = (result as AppSuccess<List<ProductVariant>>).value;
        expect(variants, hasLength(6));
        expect(
          variants.map((variant) => variant.sku.value),
          containsAll(<String>[
            'CAMISA-001-PRETO-PP',
            'CAMISA-001-PRETO-P',
            'CAMISA-001-BRANCO-M',
          ]),
        );
        expect(
          variants.every(
            (variant) => variant.status == ProductVariantStatus.active,
          ),
          isTrue,
        );
      },
    );

    test('is idempotent when the product matrix has not changed', () async {
      final first = await generate(
        organizationId: 'org-1',
        productId: 'product-1',
        generatedBy: 'user-1',
      );
      final firstIds = (first as AppSuccess<List<ProductVariant>>).value
          .map((variant) => variant.id)
          .toSet();

      final second = await generate(
        organizationId: 'org-1',
        productId: 'product-1',
        generatedBy: 'user-1',
      );
      final secondVariants = (second as AppSuccess<List<ProductVariant>>).value;

      expect(secondVariants, hasLength(6));
      expect(secondVariants.map((variant) => variant.id).toSet(), firstIds);
    });

    test('generates only missing variants when a new color is added', () async {
      await generate(
        organizationId: 'org-1',
        productId: 'product-1',
        generatedBy: 'user-1',
      );
      await colorRepository.create(color: _color('color-azul', 'AZUL'));
      final current = productRepository.products.single;
      await productRepository.update(
        product: current.copyWith(
          colorIds: const <String>['color-preto', 'color-branco', 'color-azul'],
        ),
      );

      final result = await generate(
        organizationId: 'org-1',
        productId: 'product-1',
        generatedBy: 'user-1',
      );
      final variants = (result as AppSuccess<List<ProductVariant>>).value;

      expect(variants, hasLength(9));
      expect(
        variants.where((variant) => variant.colorId == 'color-azul'),
        hasLength(3),
      );
    });
  });
}

ProductColor _color(String id, String code) {
  final now = DateTime.utc(2026, 1, 1);
  return ProductColor(
    id: id,
    organizationId: 'org-1',
    code: code,
    name: code,
    hex: HexColor.parse('#000000'),
    status: ProductColorStatus.available,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: ProductSyncStatus.synced,
  );
}

Future<void> _createTemplate(
  SizeGridTemplateRepository repository, {
  required String id,
  required List<String> labels,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return repository
      .create(
        template: SizeGridTemplate(
          id: id,
          organizationId: 'org-1',
          name: 'PP-M',
          sizes: labels.indexed
              .map((entry) {
                final (index, label) = entry;
                return SizeGridSize(
                  id: 'size-${label.toLowerCase()}',
                  organizationId: 'org-1',
                  label: label,
                  orderScore: index + 1,
                );
              })
              .toList(growable: false),
          createdAt: now,
          createdBy: 'user-1',
          updatedAt: now,
          updatedBy: 'user-1',
          version: 1,
          syncStatus: ProductSyncStatus.synced,
        ),
      )
      .then((_) {});
}

final class _InMemoryProductRepository implements ProductRepository {
  final List<Product> products = <Product>[];

  @override
  Future<AppResult<bool>> existsBySku({
    required String organizationId,
    required Sku sku,
    String? excludingProductId,
  }) async {
    return AppSuccess<bool>(
      products.any(
        (product) =>
            product.organizationId == organizationId &&
            product.sku == sku &&
            product.id != excludingProductId,
      ),
    );
  }

  @override
  Future<AppResult<Product>> create({required Product product}) async {
    products.add(product);
    return AppSuccess<Product>(product);
  }

  @override
  Future<AppResult<Product>> update({required Product product}) async {
    final index = products.indexWhere((item) => item.id == product.id);
    products[index] = product;
    return AppSuccess<Product>(product);
  }

  @override
  Future<AppResult<Product>> getById({
    required String organizationId,
    required String id,
  }) async {
    return AppSuccess<Product>(
      products.firstWhere(
        (product) =>
            product.organizationId == organizationId && product.id == id,
      ),
    );
  }

  @override
  Future<AppResult<List<Product>>> getByIds({
    required String organizationId,
    required List<String> ids,
  }) async {
    final wanted = ids.toSet();
    return AppSuccess<List<Product>>(
      products
          .where(
            (product) =>
                product.organizationId == organizationId &&
                wanted.contains(product.id),
          )
          .toList(growable: false),
    );
  }
}
