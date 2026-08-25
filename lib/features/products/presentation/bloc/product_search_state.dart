import '../../../../core/errors/errors.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_search_source.dart';
import '../../domain/entities/variant_availability.dart';

enum ProductSearchStatus { idle, loading, success, empty, failure }

final class ProductSearchState {
  const ProductSearchState({
    this.status = ProductSearchStatus.idle,
    this.organizationId = '',
    this.query = '',
    this.normalizedQuery = '',
    this.source = ProductSearchSource.remote,
    this.products = const <Product>[],
    this.availabilityByProductId = const <String, VariantAvailability>{},
    this.failure,
  });

  final ProductSearchStatus status;
  final String organizationId;
  final String query;
  final String normalizedQuery;
  final ProductSearchSource source;
  final List<Product> products;
  final Map<String, VariantAvailability> availabilityByProductId;
  final Failure? failure;

  bool get isSearching => status == ProductSearchStatus.loading;

  bool get isShowingPotentiallyStaleOfflineData =>
      source.isPotentiallyStale &&
      (status == ProductSearchStatus.success ||
          status == ProductSearchStatus.empty);

  ProductSearchState copyWith({
    ProductSearchStatus? status,
    String? organizationId,
    String? query,
    String? normalizedQuery,
    ProductSearchSource? source,
    List<Product>? products,
    Map<String, VariantAvailability>? availabilityByProductId,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return ProductSearchState(
      status: status ?? this.status,
      organizationId: organizationId ?? this.organizationId,
      query: query ?? this.query,
      normalizedQuery: normalizedQuery ?? this.normalizedQuery,
      source: source ?? this.source,
      products: products ?? this.products,
      availabilityByProductId:
          availabilityByProductId ?? this.availabilityByProductId,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }
}
