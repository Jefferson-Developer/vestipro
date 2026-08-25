import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/product_search_result.dart';
import '../entities/product_search_source.dart';
import '../repositories/product_search_repository.dart';
import '../services/product_search_normalizer.dart';

@injectable
final class SearchProductsUseCase {
  const SearchProductsUseCase(this._repository);

  final ProductSearchRepository _repository;

  Future<AppResult<ProductSearchResult>> call({
    required String organizationId,
    required String query,
    ProductSearchSource source = ProductSearchSource.remote,
    int limit = 20,
  }) {
    final normalizedOrganizationId = organizationId.trim();
    final normalizedQuery = ProductSearchNormalizer.normalize(query);
    final fieldErrors = <String, String>{};

    if (normalizedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (limit < 1 || limit > 100) {
      fieldErrors['limit'] = 'Limit must be between 1 and 100.';
    }
    if (fieldErrors.isNotEmpty) {
      return Future<AppResult<ProductSearchResult>>.value(
        AppFailure<ProductSearchResult>(
          ValidationFailure(
            'Invalid product search payload.',
            code: 'invalid_product_search_payload',
            fieldErrors: fieldErrors,
          ),
        ),
      );
    }

    if (normalizedQuery.isEmpty) {
      return Future<AppResult<ProductSearchResult>>.value(
        AppSuccess<ProductSearchResult>(
          ProductSearchResult(
            products: const <Never>[],
            source: source,
            normalizedQuery: normalizedQuery,
          ),
        ),
      );
    }

    return _repository.searchProducts(
      organizationId: normalizedOrganizationId,
      query: query,
      source: source,
      limit: limit,
    );
  }
}
