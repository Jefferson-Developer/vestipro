import '../../../../core/errors/errors.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/variant_availability.dart';

enum FavoritesLoadStatus { initial, loading, success, empty, failure }

final class FavoritesState {
  const FavoritesState({
    this.status = FavoritesLoadStatus.initial,
    this.organizationId = '',
    this.companyId,
    this.products = const <Product>[],
    this.availabilityByProductId = const <String, VariantAvailability>{},
    this.offset = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.failure,
    this.unavailableCount = 0,
    this.hasLoggedViewed = false,
  });

  final FavoritesLoadStatus status;
  final String organizationId;
  final String? companyId;

  /// Every favorited Product page loaded so far, oldest-fetched first —
  /// same "always appended, never replaced" contract `ProductGridState`
  /// already documents, so returning from a product detail never
  /// re-shuffles or drops what was already on screen.
  final List<Product> products;

  final Map<String, VariantAvailability> availabilityByProductId;

  /// Offset to request for the *next* page (`FavoriteCatalogPage.nextOffset`
  /// of the last page fetched).
  final int offset;

  final bool hasMore;
  final bool isLoadingMore;

  /// Only set when the *first* page failed and there is nothing to show at
  /// all — a later page failing never touches [products].
  final Failure? failure;

  /// How many favorited products across every page loaded so far no longer
  /// resolve to an existing Product (removed/descontinued) — surfaced
  /// explicitly by `FavoritesPage` instead of silently vanishing, per
  /// TASK-079's "nunca card quebrado" rule.
  final int unavailableCount;

  final bool hasLoggedViewed;

  bool get isInitialLoading =>
      status == FavoritesLoadStatus.initial ||
      (status == FavoritesLoadStatus.loading && products.isEmpty);

  FavoritesState copyWith({
    FavoritesLoadStatus? status,
    String? organizationId,
    String? companyId,
    List<Product>? products,
    Map<String, VariantAvailability>? availabilityByProductId,
    int? offset,
    bool? hasMore,
    bool? isLoadingMore,
    Failure? failure,
    bool clearFailure = false,
    int? unavailableCount,
    bool? hasLoggedViewed,
  }) {
    return FavoritesState(
      status: status ?? this.status,
      organizationId: organizationId ?? this.organizationId,
      companyId: companyId ?? this.companyId,
      products: products ?? this.products,
      availabilityByProductId:
          availabilityByProductId ?? this.availabilityByProductId,
      offset: offset ?? this.offset,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      failure: clearFailure ? null : failure ?? this.failure,
      unavailableCount: unavailableCount ?? this.unavailableCount,
      hasLoggedViewed: hasLoggedViewed ?? this.hasLoggedViewed,
    );
  }
}
