import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/products/products.dart';

import '../../product_factory.dart';

void main() {
  group('ProductSearchPage', () {
    testWidgets('renders offline result with stale-data notice', (
      tester,
    ) async {
      final repository = _FakeProductSearchRepository(
        products: <Product>[buildTestProduct(name: 'Camisa Basica')],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ProductSearchPage(
            organizationId: 'org-1',
            initialQuery: 'camisa',
            initialSource: ProductSearchSource.offline,
            createBloc: () => ProductSearchBloc.testing(
              searchProducts: SearchProductsUseCase(repository),
              debounceDuration: const Duration(milliseconds: 1),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Busca de produtos'), findsOneWidget);
      expect(find.text('Camisa Basica'), findsOneWidget);
      expect(
        find.text('Resultado offline: pode estar desatualizado.'),
        findsOneWidget,
      );
    });
  });
}

final class _FakeProductSearchRepository implements ProductSearchRepository {
  const _FakeProductSearchRepository({this.products = const <Product>[]});

  final List<Product> products;

  @override
  Future<AppResult<ProductSearchResult>> searchProducts({
    required String organizationId,
    required String query,
    ProductSearchSource source = ProductSearchSource.remote,
    int limit = 20,
  }) async {
    return AppSuccess<ProductSearchResult>(
      ProductSearchResult(
        products: products,
        source: source,
        normalizedQuery: ProductSearchNormalizer.normalize(query),
      ),
    );
  }
}
