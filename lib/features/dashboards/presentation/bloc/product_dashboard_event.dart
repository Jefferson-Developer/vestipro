import '../../domain/entities/product_dashboard_filters.dart';

sealed class ProductDashboardEvent {
  const ProductDashboardEvent();
}

/// First load of the Product Dashboard (TASK-137): resolves RBAC scope
/// (`ExecutiveDashboardVisibilityService`, reused verbatim — same rationale
/// `CustomerDashboardBloc`/`SalesDashboardBloc` already document), the
/// selectable company/coleção/categoria options, the KPI snapshot and the
/// ranking table for [initialFilters].
final class ProductDashboardStarted extends ProductDashboardEvent {
  const ProductDashboardStarted({
    required this.organizationId,
    required this.userId,
    required this.initialFilters,
  });

  final String organizationId;
  final String userId;
  final ProductDashboardFilters initialFilters;
}

/// The caller changed company/month/coleção/categoria/sort — reloads the KPI
/// snapshot and the ranking table for [filters], re-checking
/// `ExecutiveDashboardVisibilityFilter.canViewCompany` first (never trusting
/// a filter value the UI should not have offered), and resets the ranking's
/// visible page back to the first page.
final class ProductDashboardFiltersChanged extends ProductDashboardEvent {
  const ProductDashboardFiltersChanged(this.filters);

  final ProductDashboardFilters filters;
}

/// Re-runs the current filters' full load (ranking + KPI snapshot derived
/// from it) after a failure.
final class ProductDashboardRetried extends ProductDashboardEvent {
  const ProductDashboardRetried();
}

/// Re-runs only the ranking table load (and the KPI snapshot derived from
/// it) after a ranking-only failure.
final class ProductDashboardRankingRetried extends ProductDashboardEvent {
  const ProductDashboardRankingRetried();
}

/// Grows the ranking table's visible window by one page (seção 12.3:
/// "paginação") — purely client-side over the already-fetched, already
/// sorted/filtered rows in memory, never a new fetch of `productMonthly`;
/// only enriches the newly revealed rows with giro/imagem (see
/// `ProductDashboardBloc`'s own docs).
final class ProductDashboardRankingPageRequested extends ProductDashboardEvent {
  const ProductDashboardRankingPageRequested();
}
