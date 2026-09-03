import '../../domain/entities/sales_dashboard_filters.dart';

sealed class SalesDashboardEvent {
  const SalesDashboardEvent();
}

/// First load of the Sales Dashboard (TASK-135): resolves RBAC scope
/// (`ExecutiveDashboardVisibilityService`, reused verbatim — same
/// `report.viewSensitive` capability/company-team scoping semantics this
/// dashboard needs, see `SalesDashboardBloc`'s own docs), the selectable
/// company/team options, the KPI snapshot and the drill-down table for
/// [initialFilters].
final class SalesDashboardStarted extends SalesDashboardEvent {
  const SalesDashboardStarted({
    required this.organizationId,
    required this.userId,
    required this.initialFilters,
  });

  final String organizationId;
  final String userId;
  final SalesDashboardFilters initialFilters;
}

/// The caller changed company/team/month/grouping/comparison/sort — reloads
/// the KPI snapshot and/or the drill-down table for [filters], re-checking
/// [ExecutiveDashboardVisibilityFilter.canViewCompany]/`canViewTeam` first
/// (never trusting a filter value the UI should not have offered).
final class SalesDashboardFiltersChanged extends SalesDashboardEvent {
  const SalesDashboardFiltersChanged(this.filters);

  final SalesDashboardFilters filters;
}

/// Re-runs the current [SalesDashboardState.filters] load after a KPI
/// snapshot failure.
final class SalesDashboardRetried extends SalesDashboardEvent {
  const SalesDashboardRetried();
}

/// Re-runs only the drill-down table load after a group-rows-only failure —
/// never re-fetches the (already loaded) KPI snapshot.
final class SalesDashboardGroupRowsRetried extends SalesDashboardEvent {
  const SalesDashboardGroupRowsRetried();
}
