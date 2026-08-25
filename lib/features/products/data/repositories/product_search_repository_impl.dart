import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_search_result.dart';
import '../../domain/entities/product_search_source.dart';
import '../../domain/repositories/product_search_repository.dart';
import '../../domain/services/product_search_normalizer.dart';
import '../datasources/product_local_search_index_data_source.dart';
import '../datasources/product_remote_search_data_source.dart';

@LazySingleton(as: ProductSearchRepository)
final class ProductSearchRepositoryImpl implements ProductSearchRepository {
  const ProductSearchRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  final ProductRemoteSearchDataSource remoteDataSource;
  final ProductLocalSearchIndexDataSource localDataSource;

  @override
  Future<AppResult<ProductSearchResult>> searchProducts({
    required String organizationId,
    required String query,
    ProductSearchSource source = ProductSearchSource.remote,
    int limit = 20,
  }) async {
    final normalizedQuery = ProductSearchNormalizer.normalize(query);
    if (normalizedQuery.isEmpty) {
      return AppSuccess<ProductSearchResult>(
        ProductSearchResult(
          products: const <Never>[],
          source: source,
          normalizedQuery: normalizedQuery,
        ),
      );
    }

    try {
      final products = switch (source) {
        ProductSearchSource.remote => await remoteDataSource.searchProducts(
          organizationId: organizationId,
          normalizedQuery: normalizedQuery,
          limit: limit,
        ),
        ProductSearchSource.offline => await localDataSource.searchProducts(
          organizationId: organizationId,
          normalizedQuery: normalizedQuery,
          limit: limit,
        ),
      };

      return AppSuccess<ProductSearchResult>(
        ProductSearchResult(
          products: _tenantScopedMatches(
            products: products,
            organizationId: organizationId,
            normalizedQuery: normalizedQuery,
          ),
          source: source,
          normalizedQuery: normalizedQuery,
        ),
      );
    } on AppException catch (exception) {
      return AppFailure<ProductSearchResult>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<ProductSearchResult>(
        UnexpectedFailure(
          'Unexpected error searching products.',
          code: 'product_search_unexpected',
          cause: exception,
        ),
      );
    }
  }

  List<Product> _tenantScopedMatches({
    required List<Product> products,
    required String organizationId,
    required String normalizedQuery,
  }) {
    return products
        .where(
          (product) =>
              product.organizationId == organizationId &&
              product.deletedAt == null &&
              ProductSearchNormalizer.productMatches(product, normalizedQuery),
        )
        .toList(growable: false);
  }
}
