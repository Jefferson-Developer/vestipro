import '../../../../core/errors/errors.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/variant_availability.dart';

enum ProductGridLoadStatus { initial, loading, success, empty, failure }

final class ProductGridState {
  const ProductGridState({
    this.status = ProductGridLoadStatus.initial,
    this.organizationId = '',
    this.companyId,
    this.products = const <Product>[],
    this.availabilityByProductId = const <String, VariantAvailability>{},
    this.priceLabelsByProductId = const <String, String>{},
    this.unpricedProductIds = const <String>{},
    this.cursor,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.failure,
    this.hasLoggedViewed = false,
    this.hasPricingWarning = false,
  });

  final ProductGridLoadStatus status;
  final String organizationId;
  final String? companyId;
  final List<Product> products;
  final Map<String, VariantAvailability> availabilityByProductId;
  final Map<String, String> priceLabelsByProductId;
  final Set<String> unpricedProductIds;
  final String? cursor;
  final bool hasMore;
  final bool isLoadingMore;
  final Failure? failure;
  final bool hasLoggedViewed;
  final bool hasPricingWarning;

  bool get isInitialLoading =>
      status == ProductGridLoadStatus.initial ||
      (status == ProductGridLoadStatus.loading && products.isEmpty);

  ProductGridState copyWith({
    ProductGridLoadStatus? status,
    String? organizationId,
    String? companyId,
    List<Product>? products,
    Map<String, VariantAvailability>? availabilityByProductId,
    Map<String, String>? priceLabelsByProductId,
    Set<String>? unpricedProductIds,
    String? cursor,
    bool clearCursor = false,
    bool? hasMore,
    bool? isLoadingMore,
    Failure? failure,
    bool clearFailure = false,
    bool? hasLoggedViewed,
    bool? hasPricingWarning,
  }) {
    return ProductGridState(
      status: status ?? this.status,
      organizationId: organizationId ?? this.organizationId,
      companyId: companyId ?? this.companyId,
      products: products ?? this.products,
      availabilityByProductId:
          availabilityByProductId ?? this.availabilityByProductId,
      priceLabelsByProductId:
          priceLabelsByProductId ?? this.priceLabelsByProductId,
      unpricedProductIds: unpricedProductIds ?? this.unpricedProductIds,
      cursor: clearCursor ? null : cursor ?? this.cursor,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      failure: clearFailure ? null : failure ?? this.failure,
      hasLoggedViewed: hasLoggedViewed ?? this.hasLoggedViewed,
      hasPricingWarning: hasPricingWarning ?? this.hasPricingWarning,
    );
  }
}
