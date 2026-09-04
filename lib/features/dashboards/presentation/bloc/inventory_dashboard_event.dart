import '../../domain/entities/inventory_dashboard_filters.dart';

sealed class InventoryDashboardEvent {
  const InventoryDashboardEvent();
}

/// First load of the Inventory Dashboard (TASK-139): resolves RBAC scope
/// (`ExecutiveDashboardVisibilityService`, reused verbatim — same rationale
/// every other EPIC-17 dashboard already documents), the selectable
/// company/depósito/coleção/categoria options, the KPI snapshot and the
/// first page de "produtos parados" for [initialFilters].
final class InventoryDashboardStarted extends InventoryDashboardEvent {
  const InventoryDashboardStarted({
    required this.organizationId,
    required this.userId,
    required this.initialFilters,
  });

  final String organizationId;
  final String userId;
  final InventoryDashboardFilters initialFilters;
}

/// The caller changed empresa/mês/depósito/coleção/categoria/limiar —
/// reloads the KPI snapshot and resets "produtos parados" back to the first
/// page, re-checking `ExecutiveDashboardVisibilityFilter.canViewCompany`
/// first (never trusting a filter value the UI should not have offered).
final class InventoryDashboardFiltersChanged extends InventoryDashboardEvent {
  const InventoryDashboardFiltersChanged(this.filters);

  final InventoryDashboardFilters filters;
}

/// Re-runs the current filters' full load (KPI snapshot + first page de
/// produtos parados) after a failure.
final class InventoryDashboardRetried extends InventoryDashboardEvent {
  const InventoryDashboardRetried();
}

/// Re-runs only the "produtos parados" page load after a failure specific
/// to that list.
final class InventoryDashboardStalledProductsRetried
    extends InventoryDashboardEvent {
  const InventoryDashboardStalledProductsRetried();
}

/// Loads the next page de "produtos parados" (cursor-paginated,
/// `ProductRepository.listCatalog` under the hood) — never re-fetches
/// páginas já carregadas.
final class InventoryDashboardStalledProductsPageRequested
    extends InventoryDashboardEvent {
  const InventoryDashboardStalledProductsPageRequested();
}
