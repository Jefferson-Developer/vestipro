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
    this.cursor,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.failure,
    this.hasLoggedViewed = false,
  });

  final ProductGridLoadStatus status;
  final String organizationId;
  final String? companyId;

  /// Every Product page loaded so far, oldest-fetched first — pages are
  /// always appended, never replacing what a previous page already showed
  /// (TASK-077: rolling continuously must not duplicate or lose products
  /// already loaded, including after returning from a detail screen, since
  /// this state simply survives as long as `ProductGridBloc` is not
  /// recreated).
  final List<Product> products;

  final Map<String, VariantAvailability> availabilityByProductId;

  /// `ProductCatalogPage.nextCursor` of the last page fetched — fed back
  /// into the next `ProductGridNextPageRequested`. `null` once there is no
  /// further page ([hasMore] is `false`).
  final String? cursor;

  final bool hasMore;

  /// A next page is in flight — distinct from [status] `loading`, which is
  /// only the very first, nothing-to-show-yet load.
  final bool isLoadingMore;

  /// Only set when the *first* page failed and there is nothing to show at
  /// all. A later page failing never sets this — [products] stays exactly
  /// as it was, per the "erro em página intermediária preservando itens já
  /// exibidos" requirement.
  final Failure? failure;

  final bool hasLoggedViewed;

  bool get isInitialLoading =>
      status == ProductGridLoadStatus.initial ||
      (status == ProductGridLoadStatus.loading && products.isEmpty);

  ProductGridState copyWith({
    ProductGridLoadStatus? status,
    String? organizationId,
    String? companyId,
    List<Product>? products,
    Map<String, VariantAvailability>? availabilityByProductId,
    String? cursor,
    bool clearCursor = false,
    bool? hasMore,
    bool? isLoadingMore,
    Failure? failure,
    bool clearFailure = false,
    bool? hasLoggedViewed,
  }) {
    return ProductGridState(
      status: status ?? this.status,
      organizationId: organizationId ?? this.organizationId,
      companyId: companyId ?? this.companyId,
      products: products ?? this.products,
      availabilityByProductId:
          availabilityByProductId ?? this.availabilityByProductId,
      cursor: clearCursor ? null : cursor ?? this.cursor,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      failure: clearFailure ? null : failure ?? this.failure,
      hasLoggedViewed: hasLoggedViewed ?? this.hasLoggedViewed,
    );
  }
}
