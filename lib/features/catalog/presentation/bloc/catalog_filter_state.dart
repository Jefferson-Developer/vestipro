import '../../../../core/errors/errors.dart';
import '../../../products/domain/entities/catalog_filter.dart';
import '../../../products/domain/entities/category.dart';
import '../../../products/domain/entities/collection.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/product_color.dart';
import '../../../products/domain/entities/season.dart';
import '../../../products/domain/entities/variant_availability.dart';
import '../../domain/value_objects/catalog_view_mode.dart';

enum CatalogFilterLoadStatus {
  initial,
  loading,
  success,
  empty,
  failure,

  /// [CatalogViewMode.bestSellers]/[CatalogViewMode.recommended]: no
  /// server-side aggregation exists yet — never a fabricated/client-inferred
  /// ranking (TASK-082 business rule).
  unavailable,
}

final class CatalogFilterState {
  const CatalogFilterState({
    this.status = CatalogFilterLoadStatus.initial,
    this.organizationId = '',
    this.companyId,
    this.viewMode = CatalogViewMode.grid,
    this.filter = CatalogFilter.empty,
    this.products = const <Product>[],
    this.availabilityByProductId = const <String, VariantAvailability>{},
    this.cursor,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.failure,
    this.collections = const <Collection>[],
    this.seasons = const <Season>[],
    this.categories = const <Category>[],
    this.colors = const <ProductColor>[],
    this.sizeLabelsByTemplateId = const <String, Set<String>>{},
  });

  final CatalogFilterLoadStatus status;
  final String organizationId;
  final String? companyId;

  final CatalogViewMode viewMode;
  final CatalogFilter filter;

  /// Every Product page loaded so far for the current (viewMode, filter)
  /// combination — reset whenever either changes, same "always appended,
  /// never replacing what a previous page showed" contract
  /// `ProductGridState.products` already has for a stable (viewMode,
  /// filter).
  final List<Product> products;
  final Map<String, VariantAvailability> availabilityByProductId;

  final String? cursor;
  final bool hasMore;
  final bool isLoadingMore;

  /// Only set when the *first* page failed and there is nothing to show.
  final Failure? failure;

  /// Reference vocabulary loaded once at start, reused both by the filter
  /// panel (dropdown options) and by the active filter chips (id -> label
  /// resolution) — `CatalogFilter` itself carries no reference data.
  final List<Collection> collections;
  final List<Season> seasons;
  final List<Category> categories;
  final List<ProductColor> colors;

  /// Every `SizeGridTemplate.id` mapped to its lower-cased size labels —
  /// used both as the "tamanho" filter's option list and to narrow a
  /// fetched page by [CatalogFilter.sizes] (`Product` alone cannot answer
  /// "which sizes does this come in", only its `sizeGridTemplateId` can, via
  /// this lookup).
  final Map<String, Set<String>> sizeLabelsByTemplateId;

  bool get isInitialLoading =>
      status == CatalogFilterLoadStatus.initial ||
      (status == CatalogFilterLoadStatus.loading && products.isEmpty);

  CatalogFilterState copyWith({
    CatalogFilterLoadStatus? status,
    String? organizationId,
    String? companyId,
    CatalogViewMode? viewMode,
    CatalogFilter? filter,
    List<Product>? products,
    Map<String, VariantAvailability>? availabilityByProductId,
    String? cursor,
    bool clearCursor = false,
    bool? hasMore,
    bool? isLoadingMore,
    Failure? failure,
    bool clearFailure = false,
    List<Collection>? collections,
    List<Season>? seasons,
    List<Category>? categories,
    List<ProductColor>? colors,
    Map<String, Set<String>>? sizeLabelsByTemplateId,
  }) {
    return CatalogFilterState(
      status: status ?? this.status,
      organizationId: organizationId ?? this.organizationId,
      companyId: companyId ?? this.companyId,
      viewMode: viewMode ?? this.viewMode,
      filter: filter ?? this.filter,
      products: products ?? this.products,
      availabilityByProductId:
          availabilityByProductId ?? this.availabilityByProductId,
      cursor: clearCursor ? null : cursor ?? this.cursor,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      failure: clearFailure ? null : failure ?? this.failure,
      collections: collections ?? this.collections,
      seasons: seasons ?? this.seasons,
      categories: categories ?? this.categories,
      colors: colors ?? this.colors,
      sizeLabelsByTemplateId:
          sizeLabelsByTemplateId ?? this.sizeLabelsByTemplateId,
    );
  }
}
