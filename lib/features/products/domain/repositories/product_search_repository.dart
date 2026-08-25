import '../../../../core/utils/utils.dart';
import '../entities/product_search_result.dart';
import '../entities/product_search_source.dart';

abstract interface class ProductSearchRepository {
  Future<AppResult<ProductSearchResult>> searchProducts({
    required String organizationId,
    required String query,
    ProductSearchSource source = ProductSearchSource.remote,
    int limit = 20,
  });
}
