import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/auth/domain/services/session_service.dart';
import '../../../../core/utils/utils.dart';
import '../../../products/domain/entities/catalog_filter.dart';
import '../../../products/domain/entities/category.dart';
import '../../../products/domain/entities/collection.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/product_catalog_page.dart';
import '../../../products/domain/entities/product_color.dart';
import '../../../products/domain/entities/season.dart';
import '../../../products/domain/entities/size_grid_template.dart';
import '../../../products/domain/entities/variant_availability.dart';
import '../../../products/domain/entities/variant_availability_snapshot.dart';
import '../../../products/domain/usecases/get_variant_availability_use_case.dart';
import '../../../products/domain/usecases/list_categories_use_case.dart';
import '../../../products/domain/usecases/list_collections_use_case.dart';
import '../../../products/domain/usecases/list_product_colors_use_case.dart';
import '../../../products/domain/usecases/list_seasons_use_case.dart';
import '../../../products/domain/usecases/list_size_grid_templates_use_case.dart';
import '../../../products/domain/value_objects/variant_availability_status.dart';
import '../../domain/entities/catalog_preferences.dart';
import '../../domain/usecases/list_catalog_products_use_case.dart';
import '../../domain/usecases/load_catalog_preferences_use_case.dart';
import '../../domain/usecases/save_catalog_preferences_use_case.dart';
import '../../domain/value_objects/catalog_view_mode.dart';
import 'catalog_filter_event.dart';
import 'catalog_filter_state.dart';

/// Orchestrates the catalog's filterable browsing screen (TASK-082,
/// EPIC-10): every view mode/filter combination that is a real variation of
/// the same paginated product query (`CatalogViewMode.isBrowsedByFilterBloc`
/// — grid, list, coleção, novidades, pronta entrega), translating the
/// active `CatalogFilter` into `ListCatalogProductsUseCase`'s query instead
/// of the page ever building one itself.
///
/// `favorites`/`lookbook` are navigation shortcuts the host page decides
/// (already-built, already-tested `FavoritesPage`/`LookbookPage` —
/// duplicating them here would break this project's "não duplicar" rule);
/// `bestSellers`/`recommended` have no real data source in VestiPro yet and
/// surface `CatalogFilterLoadStatus.unavailable` instead of a fabricated
/// ranking; `byCampaign` is modeled but not wired to a campaign-scoped
/// fetch in this task (no caller selects it yet). See `CatalogViewMode`'s
/// doc for the full rationale on every mode.
@injectable
final class CatalogFilterBloc
    extends Bloc<CatalogFilterEvent, CatalogFilterState> {
  CatalogFilterBloc({
    required this.listCatalogProducts,
    required this.getVariantAvailability,
    required this.listCollections,
    required this.listSeasons,
    required this.listCategories,
    required this.listProductColors,
    required this.listSizeGridTemplates,
    required this.loadCatalogPreferences,
    required this.saveCatalogPreferences,
    required this.analyticsService,
    required this.sessionService,
  }) : super(const CatalogFilterState()) {
    on<CatalogFilterStarted>(_onStarted, transformer: restartable());
    on<CatalogFilterViewModeChanged>(
      _onViewModeChanged,
      transformer: restartable(),
    );
    on<CatalogFilterApplied>(_onFilterApplied, transformer: restartable());
    on<CatalogFilterChipRemoved>(_onChipRemoved, transformer: restartable());
    on<CatalogFilterNextPageRequested>(
      _onNextPageRequested,
      transformer: droppable(),
    );
    on<CatalogFilterRetried>(_onRetried, transformer: droppable());
    on<CatalogFilterProductOpened>(_onProductOpened);
  }

  final ListCatalogProductsUseCase listCatalogProducts;
  final GetVariantAvailabilityUseCase getVariantAvailability;
  final ListCollectionsUseCase listCollections;
  final ListSeasonsUseCase listSeasons;
  final ListCategoriesUseCase listCategories;
  final ListProductColorsUseCase listProductColors;
  final ListSizeGridTemplatesUseCase listSizeGridTemplates;
  final LoadCatalogPreferencesUseCase loadCatalogPreferences;
  final SaveCatalogPreferencesUseCase saveCatalogPreferences;
  final AnalyticsService analyticsService;
  final SessionService sessionService;

  Future<void> _onStarted(
    CatalogFilterStarted event,
    Emitter<CatalogFilterState> emit,
  ) async {
    final referenceData = await _loadReferenceData(event.organizationId);
    if (emit.isDone) return;

    final resolved = await _resolveInitialPreferences(event);
    if (emit.isDone) return;

    emit(
      CatalogFilterState(
        status: CatalogFilterLoadStatus.loading,
        organizationId: event.organizationId,
        companyId: event.companyId,
        viewMode: resolved.viewMode,
        filter: resolved.filter,
        collections: referenceData.collections,
        seasons: referenceData.seasons,
        categories: referenceData.categories,
        colors: referenceData.colors,
        sizeLabelsByTemplateId: referenceData.sizeLabelsByTemplateId,
      ),
    );
    await _persistPreferences();
    await _loadPage(emit, cursor: null, replace: true);
  }

  Future<void> _onViewModeChanged(
    CatalogFilterViewModeChanged event,
    Emitter<CatalogFilterState> emit,
  ) async {
    if (!event.viewMode.isBrowsedByFilterBloc) {
      // `favorites`/`lookbook` never reach here in practice — the host page
      // intercepts those taps and navigates away before dispatching this
      // event (see this bloc's doc). Handled defensively rather than
      // silently ignored, in case a future caller wires it directly.
      emit(
        state.copyWith(
          viewMode: event.viewMode,
          status: event.viewMode.requiresServerAggregation
              ? CatalogFilterLoadStatus.unavailable
              : state.status,
          products: const <Product>[],
          clearCursor: true,
          hasMore: false,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        viewMode: event.viewMode,
        status: CatalogFilterLoadStatus.loading,
        products: const <Product>[],
        clearCursor: true,
        hasMore: false,
      ),
    );
    await _persistPreferences();
    await _loadPage(emit, cursor: null, replace: true);
  }

  Future<void> _onFilterApplied(
    CatalogFilterApplied event,
    Emitter<CatalogFilterState> emit,
  ) async {
    await _applyFilter(emit, event.filter.normalized());
  }

  Future<void> _onChipRemoved(
    CatalogFilterChipRemoved event,
    Emitter<CatalogFilterState> emit,
  ) async {
    await _applyFilter(
      emit,
      state.filter.removing(event.key, value: event.value),
    );
  }

  Future<void> _applyFilter(
    Emitter<CatalogFilterState> emit,
    CatalogFilter nextFilter,
  ) async {
    emit(
      state.copyWith(
        filter: nextFilter,
        status: CatalogFilterLoadStatus.loading,
        products: const <Product>[],
        clearCursor: true,
        hasMore: false,
      ),
    );
    await _persistPreferences();
    await analyticsService.logEvent(
      AnalyticsEvents.catalogFiltered,
      parameters: <String, Object?>{
        'organization_id': state.organizationId,
        'view_mode': state.viewMode.code,
        'active_filter_count': nextFilter.activeCount,
        'active_filter_keys': nextFilter
            .activeEntries()
            .map((entry) => entry.$1.name)
            .toSet()
            .join(','),
      },
    );
    if (emit.isDone) return;
    await _loadPage(emit, cursor: null, replace: true);
  }

  Future<void> _onNextPageRequested(
    CatalogFilterNextPageRequested event,
    Emitter<CatalogFilterState> emit,
  ) async {
    if (state.isLoadingMore ||
        !state.hasMore ||
        state.status != CatalogFilterLoadStatus.success) {
      return;
    }
    emit(state.copyWith(isLoadingMore: true));
    await _loadPage(emit, cursor: state.cursor, replace: false);
  }

  Future<void> _onRetried(
    CatalogFilterRetried event,
    Emitter<CatalogFilterState> emit,
  ) async {
    if (state.organizationId.isEmpty) return;
    emit(state.copyWith(status: CatalogFilterLoadStatus.loading));
    await _loadPage(emit, cursor: null, replace: true);
  }

  Future<void> _onProductOpened(
    CatalogFilterProductOpened event,
    Emitter<CatalogFilterState> emit,
  ) async {
    await analyticsService.logEvent(
      AnalyticsEvents.productViewed,
      parameters: <String, Object?>{
        'organization_id': state.organizationId,
        'product_id': event.product.id,
        'source': 'catalog_filter_${state.viewMode.code}',
      },
    );
  }

  Future<void> _loadPage(
    Emitter<CatalogFilterState> emit, {
    required String? cursor,
    required bool replace,
  }) async {
    final mode = state.viewMode;
    if (!mode.isBrowsedByFilterBloc) {
      if (mode.requiresServerAggregation) {
        emit(
          state.copyWith(
            status: CatalogFilterLoadStatus.unavailable,
            isLoadingMore: false,
          ),
        );
      }
      return;
    }

    final effectiveFilter = _effectiveFilter(mode, state.filter);
    final result = await listCatalogProducts(
      organizationId: state.organizationId,
      companyId: state.companyId,
      cursor: cursor,
      filter: effectiveFilter,
    );
    if (emit.isDone) return;

    switch (result) {
      case AppSuccess<ProductCatalogPage>(value: final page):
        final availability = await _fetchAvailability(page.products);
        if (emit.isDone) return;

        final narrowed = _narrowByAvailabilityAndSize(
          page.products,
          effectiveFilter,
          availability,
        );

        final mergedProducts = replace
            ? narrowed
            : _mergeProducts(state.products, narrowed);
        final mergedAvailability = replace
            ? availability
            : <String, VariantAvailability>{
                ...state.availabilityByProductId,
                ...availability,
              };

        emit(
          state.copyWith(
            status: mergedProducts.isEmpty
                ? CatalogFilterLoadStatus.empty
                : CatalogFilterLoadStatus.success,
            products: mergedProducts,
            availabilityByProductId: mergedAvailability,
            cursor: page.nextCursor,
            clearCursor: page.nextCursor == null,
            hasMore: page.hasMore,
            isLoadingMore: false,
            clearFailure: true,
          ),
        );
      case AppFailure<ProductCatalogPage>(failure: final failure):
        if (replace) {
          emit(
            state.copyWith(
              status: CatalogFilterLoadStatus.failure,
              isLoadingMore: false,
              failure: failure,
            ),
          );
        } else {
          // A later page failing never wipes what is already on screen —
          // same contract `ProductGridBloc`/`FavoritesBloc` already have.
          emit(state.copyWith(isLoadingMore: false));
        }
    }
  }

  /// The view mode itself can force a filter dimension the user did not
  /// explicitly pick as a chip (e.g. `newArrivals` always implies
  /// "lançamento") — computed on the fly, never written back into
  /// `state.filter`, so switching away from that view mode never leaves a
  /// stray chip the user never chose.
  CatalogFilter _effectiveFilter(CatalogViewMode mode, CatalogFilter filter) {
    return switch (mode) {
      CatalogViewMode.newArrivals => filter.copyWith(launchOnly: true),
      CatalogViewMode.readyStock => filter.copyWith(
        availability: VariantAvailabilityStatus.readyStock,
      ),
      _ => filter,
    };
  }

  /// [CatalogFilter.availability]/[CatalogFilter.sizes] cannot be checked by
  /// `CatalogFilter.matches` alone (see its doc) — narrows the page
  /// `ProductRepository.listCatalog` already returned using the
  /// availability just fetched for rendering and the pre-loaded
  /// `sizeLabelsByTemplateId` lookup. A page may end up showing fewer than
  /// the requested page size when either is active; the user can simply tap
  /// "carregar mais" again, the same accepted trade-off `ProductGridBloc`
  /// already has for a later page failing outright.
  List<Product> _narrowByAvailabilityAndSize(
    List<Product> products,
    CatalogFilter filter,
    Map<String, VariantAvailability> availability,
  ) {
    if (filter.availability == null && filter.sizes.isEmpty) return products;

    return products
        .where((product) {
          if (filter.availability != null) {
            final status =
                availability[product.id]?.status ??
                VariantAvailabilityStatus.readyStock;
            if (status != filter.availability) return false;
          }
          if (filter.sizes.isNotEmpty) {
            final templateSizes =
                (state.sizeLabelsByTemplateId[product.sizeGridTemplateId] ??
                        const <String>{})
                    .map((size) => size.toLowerCase())
                    .toSet();
            final wanted = filter.sizes
                .map((size) => size.toLowerCase())
                .toSet();
            if (templateSizes.intersection(wanted).isEmpty) return false;
          }
          return true;
        })
        .toList(growable: false);
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
        <String, VariantAvailability>{
          for (final product in products)
            product.id: ?snapshot.primaryForProduct(product.id),
        },
      AppFailure<VariantAvailabilitySnapshot>() =>
        const <String, VariantAvailability>{},
    };
  }

  List<Product> _mergeProducts(List<Product> current, List<Product> nextPage) {
    final existingIds = current.map((product) => product.id).toSet();
    final newProducts = nextPage.where(
      (product) => !existingIds.contains(product.id),
    );
    return <Product>[...current, ...newProducts];
  }

  /// Reference vocabulary failing to load never blocks the browsing screen
  /// itself — same resilience precedent `_fetchAvailability` already sets —
  /// it only means the filter panel/chips show fewer options until retried.
  /// Awaited sequentially (not `Future.wait`) so every list stays strongly
  /// typed, never `dynamic`.
  Future<_ReferenceData> _loadReferenceData(String organizationId) async {
    final collectionsResult = await listCollections(organizationId);
    final seasonsResult = await listSeasons(organizationId);
    final categoriesResult = await listCategories(organizationId);
    final colorsResult = await listProductColors(organizationId);
    final templatesResult = await listSizeGridTemplates(organizationId);

    return _ReferenceData(
      collections: _unwrapOrEmpty(collectionsResult),
      seasons: _unwrapOrEmpty(seasonsResult),
      categories: _unwrapOrEmpty(categoriesResult),
      colors: _unwrapOrEmpty(colorsResult),
      sizeLabelsByTemplateId: _sizeLabelsByTemplateId(
        _unwrapOrEmpty(templatesResult),
      ),
    );
  }

  List<T> _unwrapOrEmpty<T>(AppResult<List<T>> result) {
    return switch (result) {
      AppSuccess<List<T>>(value: final value) => value,
      AppFailure<List<T>>() => const <Never>[],
    };
  }

  /// Keeps [SizeGridSize.label]'s original casing — used both to narrow a
  /// fetched page (compared case-insensitively, see
  /// [_narrowByAvailabilityAndSize]) and as the filter panel's "tamanho"
  /// option labels, where the original casing (e.g. "P"/"38") matters.
  Map<String, Set<String>> _sizeLabelsByTemplateId(
    List<SizeGridTemplate> templates,
  ) {
    return <String, Set<String>>{
      for (final template in templates)
        template.id: <String>{for (final size in template.sizes) size.label},
    };
  }

  Future<_ResolvedPreferences> _resolveInitialPreferences(
    CatalogFilterStarted event,
  ) async {
    if (event.initialViewMode != null || event.initialFilter != null) {
      return _ResolvedPreferences(
        viewMode: event.initialViewMode ?? CatalogViewMode.grid,
        filter: event.initialFilter ?? CatalogFilter.empty,
      );
    }

    final userId = sessionService.currentUser?.uid;
    if (userId == null) {
      return const _ResolvedPreferences(
        viewMode: CatalogViewMode.grid,
        filter: CatalogFilter.empty,
      );
    }

    final result = await loadCatalogPreferences(
      organizationId: event.organizationId,
      userId: userId,
    );
    final preferences = switch (result) {
      AppSuccess<CatalogPreferences?>(value: final value) => value,
      AppFailure<CatalogPreferences?>() => null,
    };
    return _ResolvedPreferences(
      viewMode: preferences?.viewMode ?? CatalogViewMode.grid,
      filter: preferences?.filter ?? CatalogFilter.empty,
    );
  }

  /// Best-effort: a signed-out session (should not normally happen on an
  /// authenticated screen) or a save failure never blocks browsing itself,
  /// it only means the next open falls back to the default view.
  Future<void> _persistPreferences() async {
    final userId = sessionService.currentUser?.uid;
    if (userId == null || state.organizationId.isEmpty) return;
    await saveCatalogPreferences(
      organizationId: state.organizationId,
      userId: userId,
      preferences: CatalogPreferences(
        viewMode: state.viewMode,
        filter: state.filter,
      ),
    );
  }
}

final class _ReferenceData {
  const _ReferenceData({
    required this.collections,
    required this.seasons,
    required this.categories,
    required this.colors,
    required this.sizeLabelsByTemplateId,
  });

  final List<Collection> collections;
  final List<Season> seasons;
  final List<Category> categories;
  final List<ProductColor> colors;
  final Map<String, Set<String>> sizeLabelsByTemplateId;
}

final class _ResolvedPreferences {
  const _ResolvedPreferences({required this.viewMode, required this.filter});

  final CatalogViewMode viewMode;
  final CatalogFilter filter;
}
