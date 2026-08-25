import 'product.dart';
import 'product_search_source.dart';

final class ProductSearchResult {
  const ProductSearchResult({
    required this.products,
    required this.source,
    required this.normalizedQuery,
  });

  final List<Product> products;
  final ProductSearchSource source;
  final String normalizedQuery;

  bool get isFromPotentiallyStaleOfflineIndex => source.isPotentiallyStale;
}
