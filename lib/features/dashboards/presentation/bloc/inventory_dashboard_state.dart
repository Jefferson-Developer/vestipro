import '../../../../core/errors/errors.dart';
import '../../domain/entities/executive_dashboard_visibility_filter.dart';
import '../../domain/entities/inventory_dashboard_filters.dart';
import '../../domain/entities/inventory_dashboard_snapshot.dart';
import '../../domain/entities/inventory_dashboard_stalled_product_row.dart';
import 'executive_dashboard_state.dart' show ExecutiveDashboardScopeOption;

enum InventoryDashboardStatus { initial, loading, forbidden, error, ready }

enum InventoryDashboardStalledProductsStatus { loading, ready, error }

final class InventoryDashboardState {
  const InventoryDashboardState({
    this.status = InventoryDashboardStatus.initial,
    this.organizationId = '',
    this.userId = '',
    this.visibilityFilter,
    this.filters = const InventoryDashboardFilters(
      companyId: '',
      year: 2024,
      month: 1,
    ),
    this.companyOptions = const <ExecutiveDashboardScopeOption>[],
    this.warehouseOptions = const <ExecutiveDashboardScopeOption>[],
    this.collectionOptions = const <ExecutiveDashboardScopeOption>[],
    this.categoryOptions = const <ExecutiveDashboardScopeOption>[],
    this.snapshot,
    this.stalledProductsStatus =
        InventoryDashboardStalledProductsStatus.loading,
    this.stalledProductRows = const <InventoryDashboardStalledProductRow>[],
    this.stalledProductsHasMore = false,
    this.stalledProductsCursor,
    this.stalledProductsFailure,
    this.failure,
  });

  final InventoryDashboardStatus status;
  final String organizationId;
  final String userId;

  /// Reuses `ExecutiveDashboardVisibilityFilter` verbatim — same RBAC
  /// scoping semantics every EPIC-17 dashboard already shares.
  final ExecutiveDashboardVisibilityFilter? visibilityFilter;
  final InventoryDashboardFilters filters;
  final List<ExecutiveDashboardScopeOption> companyOptions;
  final List<ExecutiveDashboardScopeOption> warehouseOptions;
  final List<ExecutiveDashboardScopeOption> collectionOptions;
  final List<ExecutiveDashboardScopeOption> categoryOptions;
  final InventoryDashboardSnapshot? snapshot;

  final InventoryDashboardStalledProductsStatus stalledProductsStatus;

  /// Every "produtos parados" row loaded so far (accumulates across
  /// `InventoryDashboardStalledProductsPageRequested`), never re-fetched
  /// from scratch on "carregar mais".
  final List<InventoryDashboardStalledProductRow> stalledProductRows;
  final bool stalledProductsHasMore;
  final String? stalledProductsCursor;
  final Failure? stalledProductsFailure;

  final Failure? failure;

  /// Whether the caller may pick a company other than their own — mirrors
  /// `ProductDashboardState.canPickScope`.
  bool get canPickScope =>
      visibilityFilter?.mode ==
          ExecutiveDashboardVisibilityMode.allOrganization ||
      companyOptions.length > 1;

  InventoryDashboardState copyWith({
    InventoryDashboardStatus? status,
    String? organizationId,
    String? userId,
    ExecutiveDashboardVisibilityFilter? visibilityFilter,
    InventoryDashboardFilters? filters,
    List<ExecutiveDashboardScopeOption>? companyOptions,
    List<ExecutiveDashboardScopeOption>? warehouseOptions,
    List<ExecutiveDashboardScopeOption>? collectionOptions,
    List<ExecutiveDashboardScopeOption>? categoryOptions,
    InventoryDashboardSnapshot? snapshot,
    InventoryDashboardStalledProductsStatus? stalledProductsStatus,
    List<InventoryDashboardStalledProductRow>? stalledProductRows,
    bool? stalledProductsHasMore,
    String? stalledProductsCursor,
    bool clearStalledProductsCursor = false,
    Failure? stalledProductsFailure,
    bool clearStalledProductsFailure = false,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return InventoryDashboardState(
      status: status ?? this.status,
      organizationId: organizationId ?? this.organizationId,
      userId: userId ?? this.userId,
      visibilityFilter: visibilityFilter ?? this.visibilityFilter,
      filters: filters ?? this.filters,
      companyOptions: companyOptions ?? this.companyOptions,
      warehouseOptions: warehouseOptions ?? this.warehouseOptions,
      collectionOptions: collectionOptions ?? this.collectionOptions,
      categoryOptions: categoryOptions ?? this.categoryOptions,
      snapshot: snapshot ?? this.snapshot,
      stalledProductsStatus:
          stalledProductsStatus ?? this.stalledProductsStatus,
      stalledProductRows: stalledProductRows ?? this.stalledProductRows,
      stalledProductsHasMore:
          stalledProductsHasMore ?? this.stalledProductsHasMore,
      stalledProductsCursor: clearStalledProductsCursor
          ? null
          : (stalledProductsCursor ?? this.stalledProductsCursor),
      stalledProductsFailure: clearStalledProductsFailure
          ? null
          : (stalledProductsFailure ?? this.stalledProductsFailure),
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}
