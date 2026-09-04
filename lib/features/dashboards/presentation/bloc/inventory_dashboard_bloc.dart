import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/utils/utils.dart';
import '../../../inventory/domain/entities/warehouse.dart';
import '../../../inventory/domain/usecases/get_active_warehouses_use_case.dart';
import '../../../organizations/domain/entities/company.dart';
import '../../../organizations/domain/repositories/company_repository.dart';
import '../../../products/domain/entities/category.dart';
import '../../../products/domain/entities/collection.dart';
import '../../../products/domain/repositories/category_repository.dart';
import '../../../products/domain/repositories/collection_repository.dart';
import '../../domain/entities/executive_dashboard_visibility_filter.dart';
import '../../domain/entities/inventory_dashboard_filters.dart';
import '../../domain/entities/inventory_dashboard_snapshot.dart';
import '../../domain/entities/inventory_dashboard_stalled_product_page.dart';
import '../../domain/entities/inventory_dashboard_stalled_product_row.dart';
import '../../domain/services/executive_dashboard_visibility_service.dart';
import '../../domain/usecases/load_inventory_dashboard_snapshot_use_case.dart';
import '../../domain/usecases/load_inventory_dashboard_stalled_products_use_case.dart';
import 'executive_dashboard_state.dart' show ExecutiveDashboardScopeOption;
import 'inventory_dashboard_event.dart';
import 'inventory_dashboard_state.dart';

/// Drives the Inventory Dashboard (TASK-139, EPIC-17): resolves which
/// companies the caller may pick as scope, then loads the KPI card
/// (cobertura/sell-through/giro + alertas de ruptura consolidados) via
/// [LoadInventoryDashboardSnapshotUseCase] (TASK-094/TASK-093) and a
/// paginated "produtos parados" list via
/// [LoadInventoryDashboardStalledProductsUseCase] — never a raw query
/// against `orders`/`products`/`stockAlerts`.
@injectable
final class InventoryDashboardBloc
    extends Bloc<InventoryDashboardEvent, InventoryDashboardState> {
  InventoryDashboardBloc(
    this._visibilityService,
    this._loadSnapshot,
    this._loadStalledProducts,
    this._companyRepository,
    this._getActiveWarehouses,
    this._collectionRepository,
    this._categoryRepository,
    this._analyticsService,
  ) : super(const InventoryDashboardState()) {
    on<InventoryDashboardStarted>(_onStarted);
    on<InventoryDashboardFiltersChanged>(_onFiltersChanged);
    on<InventoryDashboardRetried>(_onRetried);
    on<InventoryDashboardStalledProductsRetried>(_onStalledProductsRetried);
    on<InventoryDashboardStalledProductsPageRequested>(
      _onStalledProductsPageRequested,
    );
  }

  final ExecutiveDashboardVisibilityService _visibilityService;
  final LoadInventoryDashboardSnapshotUseCase _loadSnapshot;
  final LoadInventoryDashboardStalledProductsUseCase _loadStalledProducts;
  final CompanyRepository _companyRepository;
  final GetActiveWarehousesUseCase _getActiveWarehouses;
  final CollectionRepository _collectionRepository;
  final CategoryRepository _categoryRepository;
  final AnalyticsService _analyticsService;

  /// Cached only for the lifetime of the current `filters.companyId`, so
  /// [LoadInventoryDashboardSnapshotUseCase]'s bounded fan-out sempre lê o
  /// depósito ativo mais recente sem precisar de um segundo parâmetro de
  /// evento só para isso.
  List<Warehouse> _activeWarehouses = const <Warehouse>[];

  Future<void> _onStarted(
    InventoryDashboardStarted event,
    Emitter<InventoryDashboardState> emit,
  ) async {
    emit(
      InventoryDashboardState(
        status: InventoryDashboardStatus.loading,
        organizationId: event.organizationId,
        userId: event.userId,
        filters: event.initialFilters,
      ),
    );

    final visibilityResult = await _visibilityService.resolve(
      organizationId: event.organizationId,
      userId: event.userId,
    );
    if (visibilityResult case AppFailure<ExecutiveDashboardVisibilityFilter>(
      failure: final failure,
    )) {
      emit(
        state.copyWith(
          status: InventoryDashboardStatus.error,
          failure: failure,
        ),
      );
      return;
    }
    final visibility =
        (visibilityResult as AppSuccess<ExecutiveDashboardVisibilityFilter>)
            .value;
    emit(state.copyWith(visibilityFilter: visibility));

    if (!visibility.canViewAny) {
      emit(state.copyWith(status: InventoryDashboardStatus.forbidden));
      return;
    }

    final companiesResult = await _companyRepository.listByOrganization(
      event.organizationId,
    );
    if (companiesResult case AppFailure<List<Company>>(
      failure: final failure,
    )) {
      emit(
        state.copyWith(
          status: InventoryDashboardStatus.error,
          failure: failure,
        ),
      );
      return;
    }
    final companies = (companiesResult as AppSuccess<List<Company>>).value
        .where(
          (company) =>
              company.deletedAt == null &&
              visibility.canViewCompany(company.id),
        )
        .toList(growable: false);

    final companyOptions = <ExecutiveDashboardScopeOption>[
      for (final company in companies)
        ExecutiveDashboardScopeOption(id: company.id, name: company.name),
    ];

    final collectionsResult = await _collectionRepository.listByOrganization(
      event.organizationId,
    );
    final collectionOptions = switch (collectionsResult) {
      AppSuccess<List<Collection>>(value: final collections) =>
        <ExecutiveDashboardScopeOption>[
          for (final collection in collections)
            if (collection.deletedAt == null)
              ExecutiveDashboardScopeOption(
                id: collection.id,
                name: collection.name,
              ),
        ],
      AppFailure<List<Collection>>() => const <ExecutiveDashboardScopeOption>[],
    };

    final categoriesResult = await _categoryRepository.listByOrganization(
      event.organizationId,
    );
    final categoryOptions = switch (categoriesResult) {
      AppSuccess<List<Category>>(value: final categories) =>
        <ExecutiveDashboardScopeOption>[
          for (final category in categories)
            if (category.deletedAt == null)
              ExecutiveDashboardScopeOption(
                id: category.id,
                name: category.name,
              ),
        ],
      AppFailure<List<Category>>() => const <ExecutiveDashboardScopeOption>[],
    };

    var effectiveFilters = event.initialFilters;
    if (companies.isNotEmpty &&
        !companies.any((company) => company.id == effectiveFilters.companyId)) {
      effectiveFilters = effectiveFilters.copyWith(
        companyId: companies.first.id,
      );
    }

    emit(
      state.copyWith(
        companyOptions: companyOptions,
        collectionOptions: collectionOptions,
        categoryOptions: categoryOptions,
        filters: effectiveFilters,
      ),
    );

    await _load(effectiveFilters, emit);
  }

  Future<void> _onFiltersChanged(
    InventoryDashboardFiltersChanged event,
    Emitter<InventoryDashboardState> emit,
  ) async {
    final visibility = state.visibilityFilter;
    if (visibility == null || !visibility.canViewAny) return;
    if (!visibility.canViewCompany(event.filters.companyId)) return;

    emit(
      state.copyWith(
        status: InventoryDashboardStatus.loading,
        filters: event.filters,
      ),
    );
    await _load(event.filters, emit);
  }

  Future<void> _onRetried(
    InventoryDashboardRetried event,
    Emitter<InventoryDashboardState> emit,
  ) async {
    final visibility = state.visibilityFilter;
    if (visibility == null) return;
    emit(
      state.copyWith(
        status: InventoryDashboardStatus.loading,
        clearFailure: true,
      ),
    );
    await _load(state.filters, emit);
  }

  Future<void> _onStalledProductsRetried(
    InventoryDashboardStalledProductsRetried event,
    Emitter<InventoryDashboardState> emit,
  ) async {
    await _loadStalledProductsFirstPage(state.filters, emit);
  }

  Future<void> _onStalledProductsPageRequested(
    InventoryDashboardStalledProductsPageRequested event,
    Emitter<InventoryDashboardState> emit,
  ) async {
    if (!state.stalledProductsHasMore) return;

    final result = await _loadStalledProducts(
      organizationId: state.organizationId,
      filters: state.filters,
      cursor: state.stalledProductsCursor,
    );
    if (emit.isDone) return;

    switch (result) {
      case AppFailure(failure: final failure):
        emit(
          state.copyWith(
            stalledProductsStatus:
                InventoryDashboardStalledProductsStatus.error,
            stalledProductsFailure: failure,
          ),
        );
        return;
      case AppSuccess(value: final InventoryDashboardStalledProductPage page):
        emit(
          state.copyWith(
            stalledProductsStatus:
                InventoryDashboardStalledProductsStatus.ready,
            stalledProductRows: <InventoryDashboardStalledProductRow>[
              ...state.stalledProductRows,
              ...page.rows,
            ],
            stalledProductsHasMore: page.hasMore,
            stalledProductsCursor: page.nextCursor,
            clearStalledProductsCursor: page.nextCursor == null,
            clearStalledProductsFailure: true,
          ),
        );
    }
  }

  Future<void> _load(
    InventoryDashboardFilters filters,
    Emitter<InventoryDashboardState> emit,
  ) async {
    final warehousesResult = await _getActiveWarehouses(
      organizationId: state.organizationId,
      companyId: filters.companyId,
    );
    _activeWarehouses = switch (warehousesResult) {
      AppSuccess<List<Warehouse>>(value: final warehouses) => warehouses,
      AppFailure<List<Warehouse>>() => const <Warehouse>[],
    };
    final warehouseOptions = <ExecutiveDashboardScopeOption>[
      for (final warehouse in _activeWarehouses)
        ExecutiveDashboardScopeOption(id: warehouse.id, name: warehouse.name),
    ];
    emit(state.copyWith(warehouseOptions: warehouseOptions));

    final snapshotResult = await _loadSnapshot(
      organizationId: state.organizationId,
      requestedByUserId: state.userId,
      filters: filters,
      activeWarehouses: _activeWarehouses,
    );
    if (emit.isDone) return;

    switch (snapshotResult) {
      case AppFailure(failure: final failure):
        emit(
          state.copyWith(
            status: InventoryDashboardStatus.error,
            failure: failure,
          ),
        );
        return;
      case AppSuccess(value: final InventoryDashboardSnapshot snapshot):
        emit(
          state.copyWith(
            status: InventoryDashboardStatus.ready,
            snapshot: snapshot,
            clearFailure: true,
          ),
        );
    }

    await _loadStalledProductsFirstPage(filters, emit);

    unawaited(
      _analyticsService.logEvent(
        AnalyticsEvents.dashboardViewed,
        parameters: <String, Object?>{
          'organization_id': state.organizationId,
          'dashboard_type': 'inventory',
          'company_id': filters.companyId,
          'month': filters.monthKey,
          'warehouse_id': filters.warehouseId,
          'collection_id': filters.collectionId,
          'category_id': filters.categoryId,
        },
      ),
    );
  }

  Future<void> _loadStalledProductsFirstPage(
    InventoryDashboardFilters filters,
    Emitter<InventoryDashboardState> emit,
  ) async {
    emit(
      state.copyWith(
        stalledProductsStatus: InventoryDashboardStalledProductsStatus.loading,
        clearStalledProductsFailure: true,
      ),
    );

    final result = await _loadStalledProducts(
      organizationId: state.organizationId,
      filters: filters,
    );
    if (emit.isDone) return;

    switch (result) {
      case AppFailure(failure: final failure):
        emit(
          state.copyWith(
            stalledProductsStatus:
                InventoryDashboardStalledProductsStatus.error,
            stalledProductsFailure: failure,
          ),
        );
      case AppSuccess(value: final InventoryDashboardStalledProductPage page):
        emit(
          state.copyWith(
            stalledProductsStatus:
                InventoryDashboardStalledProductsStatus.ready,
            stalledProductRows: page.rows,
            stalledProductsHasMore: page.hasMore,
            stalledProductsCursor: page.nextCursor,
            clearStalledProductsCursor: page.nextCursor == null,
          ),
        );
    }
  }
}
