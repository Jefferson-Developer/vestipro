import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/catalog/catalog.dart';
import 'package:vestipro/features/products/products.dart';

import '../../catalog_test_fakes.dart';

void main() {
  group('ListCampaignRelatedProductsUseCase', () {
    late InMemoryCatalogProductRepository productRepository;
    late ListCampaignRelatedProductsUseCase useCase;

    setUp(() {
      productRepository = InMemoryCatalogProductRepository();
      useCase = ListCampaignRelatedProductsUseCase(productRepository);
    });

    test('resolves related product ids into full products', () async {
      productRepository.products.addAll(<Product>[
        buildTestCatalogHomeProduct(id: 'product-1'),
        buildTestCatalogHomeProduct(id: 'product-2'),
      ]);

      final result = await useCase.call(
        organizationId: 'org-1',
        productIds: <String>['product-1'],
      );

      expect(result, isA<AppSuccess<List<Product>>>());
      expect(
        (result as AppSuccess<List<Product>>).value.map((p) => p.id),
        <String>['product-1'],
      );
    });

    test('silently skips a stale/removed product id', () async {
      productRepository.products.add(
        buildTestCatalogHomeProduct(id: 'product-1'),
      );

      final result = await useCase.call(
        organizationId: 'org-1',
        productIds: <String>['product-1', 'deleted-product'],
      );

      expect(result, isA<AppSuccess<List<Product>>>());
      expect(
        (result as AppSuccess<List<Product>>).value.map((p) => p.id),
        <String>['product-1'],
      );
    });

    test('returns an empty list without querying the repository when there '
        'are no ids', () async {
      final result = await useCase.call(
        organizationId: 'org-1',
        productIds: const <String>[],
      );

      expect(result, isA<AppSuccess<List<Product>>>());
      expect((result as AppSuccess<List<Product>>).value, isEmpty);
    });
  });
}
