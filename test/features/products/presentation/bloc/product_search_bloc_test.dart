import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/products/products.dart';

import '../../product_factory.dart';

void main() {
  group('ProductSearchBloc', () {
    late _FakeProductSearchRepository repository;

    blocTest<ProductSearchBloc, ProductSearchState>(
      'debounces query changes before calling the use case',
      build: () {
        repository = _FakeProductSearchRepository();
        return ProductSearchBloc.testing(
          searchProducts: SearchProductsUseCase(repository),
          getVariantAvailability: GetVariantAvailabilityUseCase(
            const _FakeVariantAvailabilityRepository(),
          ),
          debounceDuration: const Duration(milliseconds: 40),
        )..add(const ProductSearchStarted(organizationId: 'org-1'));
      },
      act: (bloc) => bloc.add(const ProductSearchQueryChanged('camisa')),
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(repository.calls, isEmpty);
      },
    );

    blocTest<ProductSearchBloc, ProductSearchState>(
      'keeps the latest result when a slower previous search finishes later',
      build: () {
        repository = _FakeProductSearchRepository(
          delayForQuery: (query) => query == 'camisa'
              ? const Duration(milliseconds: 40)
              : const Duration(milliseconds: 1),
          productsForQuery: (query) => query == 'camisa'
              ? <Product>[buildTestProduct(id: 'old', name: 'Camisa Linho')]
              : <Product>[buildTestProduct(id: 'new', name: 'Calca Reta')],
        );
        return ProductSearchBloc.testing(
          searchProducts: SearchProductsUseCase(repository),
          getVariantAvailability: GetVariantAvailabilityUseCase(
            const _FakeVariantAvailabilityRepository(),
          ),
          debounceDuration: const Duration(milliseconds: 1),
        );
      },
      act: (bloc) async {
        bloc.add(const ProductSearchStarted(organizationId: 'org-1'));
        bloc.add(const ProductSearchQueryChanged('camisa'));
        await Future<void>.delayed(const Duration(milliseconds: 5));
        bloc.add(const ProductSearchQueryChanged('calca'));
      },
      wait: const Duration(milliseconds: 80),
      verify: (bloc) {
        expect(bloc.state.status, ProductSearchStatus.success);
        expect(bloc.state.products.single.id, 'new');
      },
    );

    blocTest<ProductSearchBloc, ProductSearchState>(
      'emits empty when the search succeeds without results',
      build: () {
        repository = _FakeProductSearchRepository();
        return ProductSearchBloc.testing(
          searchProducts: SearchProductsUseCase(repository),
          getVariantAvailability: GetVariantAvailabilityUseCase(
            const _FakeVariantAvailabilityRepository(),
          ),
          debounceDuration: const Duration(milliseconds: 1),
        );
      },
      act: (bloc) {
        bloc.add(const ProductSearchStarted(organizationId: 'org-1'));
        bloc.add(const ProductSearchQueryChanged('sem resultado'));
      },
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        expect(bloc.state.status, ProductSearchStatus.empty);
        expect(bloc.state.products, isEmpty);
      },
    );
  });
}

final class _FakeVariantAvailabilityRepository
    implements VariantAvailabilityRepository {
  const _FakeVariantAvailabilityRepository();

  @override
  Future<AppResult<List<VariantAvailability>>> listByProductIds({
    required String organizationId,
    required Iterable<String> productIds,
  }) async {
    return const AppSuccess<List<VariantAvailability>>(<VariantAvailability>[]);
  }

  @override
  Future<AppResult<List<VariantAvailability>>> listByVariantIds({
    required String organizationId,
    required Iterable<String> variantIds,
  }) async {
    return const AppSuccess<List<VariantAvailability>>(<VariantAvailability>[]);
  }
}

final class _FakeProductSearchRepository implements ProductSearchRepository {
  _FakeProductSearchRepository({
    Duration Function(String query)? delayForQuery,
    List<Product> Function(String query)? productsForQuery,
  }) : _delayForQuery = delayForQuery ?? ((_) => Duration.zero),
       _productsForQuery = productsForQuery ?? ((_) => const <Product>[]);

  final Duration Function(String query) _delayForQuery;
  final List<Product> Function(String query) _productsForQuery;
  final List<_SearchCall> calls = <_SearchCall>[];

  @override
  Future<AppResult<ProductSearchResult>> searchProducts({
    required String organizationId,
    required String query,
    ProductSearchSource source = ProductSearchSource.remote,
    int limit = 20,
  }) async {
    calls.add(_SearchCall(query: query, source: source));
    await Future<void>.delayed(_delayForQuery(query));
    return AppSuccess<ProductSearchResult>(
      ProductSearchResult(
        products: _productsForQuery(query),
        source: source,
        normalizedQuery: ProductSearchNormalizer.normalize(query),
      ),
    );
  }
}

final class _SearchCall {
  const _SearchCall({required this.query, required this.source});

  final String query;
  final ProductSearchSource source;
}
