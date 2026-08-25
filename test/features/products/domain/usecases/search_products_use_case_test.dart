import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/products/products.dart';

import '../../product_factory.dart';

void main() {
  group('SearchProductsUseCase', () {
    test(
      'returns empty result for blank query without hitting repository',
      () async {
        final repository = _FakeProductSearchRepository();
        final useCase = SearchProductsUseCase(repository);

        final result = await useCase(
          organizationId: 'org-1',
          query: '   ',
          source: ProductSearchSource.offline,
        );

        expect(repository.calls, isEmpty);
        expect(result, isA<AppSuccess<ProductSearchResult>>());
        final value = (result as AppSuccess<ProductSearchResult>).value;
        expect(value.products, isEmpty);
        expect(value.source, ProductSearchSource.offline);
      },
    );

    test('validates organization and limit', () async {
      final repository = _FakeProductSearchRepository();
      final useCase = SearchProductsUseCase(repository);

      final result = await useCase(
        organizationId: ' ',
        query: 'camisa',
        limit: 0,
      );

      expect(repository.calls, isEmpty);
      expect(result, isA<AppFailure<ProductSearchResult>>());
      final failure = (result as AppFailure<ProductSearchResult>).failure;
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure).fieldErrors.keys,
        contains('limit'),
      );
    });

    test('delegates non-empty searches preserving source and limit', () async {
      final product = buildTestProduct();
      final repository = _FakeProductSearchRepository(
        result: AppSuccess<ProductSearchResult>(
          ProductSearchResult(
            products: <Product>[product],
            source: ProductSearchSource.remote,
            normalizedQuery: 'camisa',
          ),
        ),
      );
      final useCase = SearchProductsUseCase(repository);

      final result = await useCase(
        organizationId: ' org-1 ',
        query: 'Camisa',
        source: ProductSearchSource.remote,
        limit: 10,
      );

      expect(result, isA<AppSuccess<ProductSearchResult>>());
      expect(repository.calls.single.organizationId, 'org-1');
      expect(repository.calls.single.query, 'Camisa');
      expect(repository.calls.single.source, ProductSearchSource.remote);
      expect(repository.calls.single.limit, 10);
    });
  });
}

final class _FakeProductSearchRepository implements ProductSearchRepository {
  _FakeProductSearchRepository({AppResult<ProductSearchResult>? result})
    : _result =
          result ??
          const AppSuccess<ProductSearchResult>(
            ProductSearchResult(
              products: <Product>[],
              source: ProductSearchSource.remote,
              normalizedQuery: '',
            ),
          );

  final AppResult<ProductSearchResult> _result;
  final List<_SearchCall> calls = <_SearchCall>[];

  @override
  Future<AppResult<ProductSearchResult>> searchProducts({
    required String organizationId,
    required String query,
    ProductSearchSource source = ProductSearchSource.remote,
    int limit = 20,
  }) async {
    calls.add(
      _SearchCall(
        organizationId: organizationId,
        query: query,
        source: source,
        limit: limit,
      ),
    );
    return _result;
  }
}

final class _SearchCall {
  const _SearchCall({
    required this.organizationId,
    required this.query,
    required this.source,
    required this.limit,
  });

  final String organizationId;
  final String query;
  final ProductSearchSource source;
  final int limit;
}
