import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/utils/utils.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/product_catalog_page.dart';
import '../../../products/domain/entities/variant_availability.dart';
import '../../../products/domain/entities/variant_availability_snapshot.dart';
import '../../../products/domain/usecases/get_variant_availability_use_case.dart';
import '../../domain/usecases/list_catalog_products_use_case.dart';
import 'product_grid_event.dart';
import 'product_grid_state.dart';

/// Orchestrates the catalog's visual grid (TASK-077) — the cursor-paginated
/// product listing every catalog surface (home "ver tudo", busca, coleção,
/// campanha, favoritos) reuses, always rendered through the Design System's
/// `AppProductGrid`/`AppProductCardData`.
///
/// Every page fetched is appended to [ProductGridState.products], never
/// replacing it, so scrolling never duplicates or loses a product already
/// shown; the same state also simply survives a push to a detail screen and
/// back, as long as this bloc instance is not recreated (owned by
/// `ProductGridPage`'s `BlocProvider`, one level above the pushed route).
@injectable
final class ProductGridBloc extends Bloc<ProductGridEvent, ProductGridState> {
  ProductGridBloc({
    required this.listCatalogProducts,
    required this.getVariantAvailability,
    required this.analyticsService,
  }) : super(const ProductGridState()) {
    on<ProductGridStarted>(_onStarted, transformer: restartable());
    on<ProductGridNextPageRequested>(
      _onNextPageRequested,
      transformer: droppable(),
    );
    on<ProductGridRetried>(_onRetried, transformer: droppable());
    on<ProductGridProductOpened>(_onProductOpened);
  }

  final ListCatalogProductsUseCase listCatalogProducts;
  final GetVariantAvailabilityUseCase getVariantAvailability;
  final AnalyticsService analyticsService;

  Future<void> _onStarted(
    ProductGridStarted event,
    Emitter<ProductGridState> emit,
  ) async {
    emit(
      ProductGridState(
        status: ProductGridLoadStatus.loading,
        organizationId: event.organizationId,
        companyId: event.companyId,
      ),
    );
    await _loadPage(emit, cursor: null, replace: true);
  }

  Future<void> _onNextPageRequested(
    ProductGridNextPageRequested event,
    Emitter<ProductGridState> emit,
  ) async {
    if (state.isLoadingMore ||
        !state.hasMore ||
        state.status != ProductGridLoadStatus.success) {
      return;
    }
    emit(state.copyWith(isLoadingMore: true));
    await _loadPage(emit, cursor: state.cursor, replace: false);
  }

  Future<void> _onRetried(
    ProductGridRetried event,
    Emitter<ProductGridState> emit,
  ) async {
    if (state.organizationId.isEmpty) return;
    emit(state.copyWith(status: ProductGridLoadStatus.loading));
    await _loadPage(emit, cursor: null, replace: true);
  }

  Future<void> _onProductOpened(
    ProductGridProductOpened event,
    Emitter<ProductGridState> emit,
  ) async {
    await analyticsService.logEvent(
      AnalyticsEvents.productViewed,
      parameters: <String, Object?>{
        'organization_id': state.organizationId,
        'product_id': event.product.id,
        'source': 'catalog_grid',
      },
    );
  }

  Future<void> _loadPage(
    Emitter<ProductGridState> emit, {
    required String? cursor,
    required bool replace,
  }) async {
    final result = await listCatalogProducts(
      organizationId: state.organizationId,
      companyId: state.companyId,
      cursor: cursor,
    );
    if (emit.isDone) return;

    switch (result) {
      case AppSuccess<ProductCatalogPage>(value: final page):
        final mergedProducts = replace
            ? page.products
            : _mergeProducts(state.products, page.products);
        final availability = await _fetchAvailability(page.products);
        if (emit.isDone) return;
        final mergedAvailability = replace
            ? availability
            : <String, VariantAvailability>{
                ...state.availabilityByProductId,
                ...availability,
              };

        emit(
          state.copyWith(
            status: mergedProducts.isEmpty
                ? ProductGridLoadStatus.empty
                : ProductGridLoadStatus.success,
            products: mergedProducts,
            availabilityByProductId: mergedAvailability,
            cursor: page.nextCursor,
            clearCursor: page.nextCursor == null,
            hasMore: page.hasMore,
            isLoadingMore: false,
            clearFailure: true,
          ),
        );
        await _logViewedIfNeeded(emit);
      case AppFailure<ProductCatalogPage>(failure: final failure):
        if (replace) {
          emit(
            state.copyWith(
              status: ProductGridLoadStatus.failure,
              isLoadingMore: false,
              failure: failure,
            ),
          );
        } else {
          // A later page failing never wipes what is already on screen —
          // just stop the "carregar mais" spinner so the user can retry by
          // tapping it again.
          emit(state.copyWith(isLoadingMore: false));
        }
    }
  }

  Future<Map<String, VariantAvailability>> _fetchAvailability(
    List<Product> products,
  ) async {
    if (products.isEmpty) return const <String, VariantAvailability>{};
    final result = await getVariantAvailability(
      organizationId: state.organizationId,
      productIds: products.map((product) => product.id),
    );
    return switch (result) {
      AppSuccess<VariantAvailabilitySnapshot>(value: final snapshot) =>
        _availabilityByProductId(products, snapshot),
      // Availability failing to load never fails the whole grid — a card
      // with no known availability falls back to `AppProductCardData`'s own
      // default (ready stock), exactly like `ProductSearchPage` already
      // does for the same reason.
      AppFailure<VariantAvailabilitySnapshot>() =>
        const <String, VariantAvailability>{},
    };
  }

  Map<String, VariantAvailability> _availabilityByProductId(
    List<Product> products,
    VariantAvailabilitySnapshot snapshot,
  ) {
    final result = <String, VariantAvailability>{};
    for (final product in products) {
      final availability = snapshot.primaryForProduct(product.id);
      if (availability != null) {
        result[product.id] = availability;
      }
    }
    return result;
  }

  /// Appends [nextPage] to [current], skipping any product id already
  /// present — defensive de-duplication against a duplicated/concurrent
  /// page load, on top of `ProductGridNextPageRequested`'s own `droppable`
  /// transformer and the `isLoadingMore` guard.
  List<Product> _mergeProducts(List<Product> current, List<Product> nextPage) {
    final existingIds = current.map((product) => product.id).toSet();
    final newProducts = nextPage.where(
      (product) => !existingIds.contains(product.id),
    );
    return <Product>[...current, ...newProducts];
  }

  Future<void> _logViewedIfNeeded(Emitter<ProductGridState> emit) async {
    if (state.hasLoggedViewed || state.products.isEmpty) return;
    await analyticsService.logEvent(
      AnalyticsEvents.catalogGridViewed,
      parameters: <String, Object?>{
        'organization_id': state.organizationId,
        'products_count': state.products.length,
      },
    );
    if (emit.isDone) return;
    emit(state.copyWith(hasLoggedViewed: true));
  }
}
