import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/products/data/datasources/product_local_search_index_data_source.dart';
import 'package:vestipro/features/products/data/datasources/product_remote_search_data_source.dart';
import 'package:vestipro/features/products/data/repositories/product_search_repository_impl.dart';
import 'package:vestipro/features/products/products.dart';

import '../../product_factory.dart';

void main() {
  group('ProductSearchRepositoryImpl', () {
    test(
      'uses the remote source and filters stale tenant results defensively',
      () async {
        final matching = buildTestProduct(
          id: 'product-1',
          name: 'Camisa Linho',
        );
        final otherTenant = buildTestProduct(
          id: 'product-2',
          organizationId: 'org-2',
          name: 'Camisa Linho',
        );
        final deleted = buildTestProduct(
          id: 'product-3',
          name: 'Camisa Linho',
          deletedAt: DateTime.utc(2026, 1, 2),
        );
        final repository = ProductSearchRepositoryImpl(
          remoteDataSource: _FakeRemoteSearchDataSource(
            products: <Product>[matching, otherTenant, deleted],
          ),
          localDataSource: _FakeLocalSearchIndexDataSource(),
        );

        final result = await repository.searchProducts(
          organizationId: 'org-1',
          query: 'linho',
        );

        expect(result, isA<AppSuccess<ProductSearchResult>>());
        final value = (result as AppSuccess<ProductSearchResult>).value;
        expect(value.source, ProductSearchSource.remote);
        expect(value.products, <Product>[matching]);
      },
    );

    test(
      'uses the offline index and marks result origin as potentially stale',
      () async {
        final product = buildTestProduct(name: 'Vestido Trico');
        final repository = ProductSearchRepositoryImpl(
          remoteDataSource: _FakeRemoteSearchDataSource(),
          localDataSource: _FakeLocalSearchIndexDataSource(
            products: <Product>[product],
          ),
        );

        final result = await repository.searchProducts(
          organizationId: 'org-1',
          query: 'trico',
          source: ProductSearchSource.offline,
        );

        expect(result, isA<AppSuccess<ProductSearchResult>>());
        final value = (result as AppSuccess<ProductSearchResult>).value;
        expect(value.source, ProductSearchSource.offline);
        expect(value.isFromPotentiallyStaleOfflineIndex, isTrue);
        expect(value.products.single, product);
      },
    );

    test(
      'remote and offline sources agree for the same indexed term',
      () async {
        final product = buildTestProduct(
          id: 'product-1',
          name: 'Jaqueta Matelasse',
          tags: const <String>['inverno'],
        );
        final repository = ProductSearchRepositoryImpl(
          remoteDataSource: _FakeRemoteSearchDataSource(
            products: <Product>[product],
          ),
          localDataSource: _FakeLocalSearchIndexDataSource(
            products: <Product>[product],
          ),
        );

        final remote = await repository.searchProducts(
          organizationId: 'org-1',
          query: 'inverno',
        );
        final offline = await repository.searchProducts(
          organizationId: 'org-1',
          query: 'inverno',
          source: ProductSearchSource.offline,
        );

        expect(
          (remote as AppSuccess<ProductSearchResult>).value.products,
          (offline as AppSuccess<ProductSearchResult>).value.products,
        );
      },
    );
  });
}

final class _FakeRemoteSearchDataSource
    implements ProductRemoteSearchDataSource {
  const _FakeRemoteSearchDataSource({this.products = const <Product>[]});

  final List<Product> products;

  @override
  Future<List<Product>> searchProducts({
    required String organizationId,
    required String normalizedQuery,
    int limit = 20,
  }) async {
    return products.take(limit).toList(growable: false);
  }
}

final class _FakeLocalSearchIndexDataSource
    implements ProductLocalSearchIndexDataSource {
  const _FakeLocalSearchIndexDataSource({this.products = const <Product>[]});

  final List<Product> products;

  @override
  Future<void> replaceProducts({
    required String organizationId,
    required List<Product> products,
  }) async {}

  @override
  Future<List<Product>> searchProducts({
    required String organizationId,
    required String normalizedQuery,
    int limit = 20,
  }) async {
    return products.take(limit).toList(growable: false);
  }

  @override
  Future<void> upsertProduct({required Product product}) async {}
}
