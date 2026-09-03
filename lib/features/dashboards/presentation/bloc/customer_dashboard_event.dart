import '../../domain/entities/customer_dashboard_filters.dart';

sealed class CustomerDashboardEvent {
  const CustomerDashboardEvent();
}

/// First load of the Customer Dashboard (TASK-136): resolves RBAC scope
/// (`ExecutiveDashboardVisibilityService`, reused verbatim — see
/// `CustomerDashboardBloc`'s own docs for why), the selectable company/team
/// options, the KPI snapshot and the ranking table for [initialFilters].
final class CustomerDashboardStarted extends CustomerDashboardEvent {
  const CustomerDashboardStarted({
    required this.organizationId,
    required this.userId,
    required this.initialFilters,
  });

  final String organizationId;
  final String userId;
  final CustomerDashboardFilters initialFilters;
}

/// The caller changed company/team/month/segment/sort — reloads the KPI
/// snapshot and the ranking table for [filters], re-checking
/// [ExecutiveDashboardVisibilityFilter.canViewCompany]/`canViewTeam` first
/// (never trusting a filter value the UI should not have offered), and
/// resets the ranking's visible page back to the first page.
final class CustomerDashboardFiltersChanged extends CustomerDashboardEvent {
  const CustomerDashboardFiltersChanged(this.filters);

  final CustomerDashboardFilters filters;
}

/// Re-runs the current [CustomerDashboardState.filters] load after a KPI
/// snapshot failure.
final class CustomerDashboardRetried extends CustomerDashboardEvent {
  const CustomerDashboardRetried();
}

/// Re-runs only the ranking table load after a ranking-only failure — never
/// re-fetches the (already loaded) KPI snapshot.
final class CustomerDashboardRankingRetried extends CustomerDashboardEvent {
  const CustomerDashboardRankingRetried();
}

/// Grows the ranking table's visible window by one page (seção 12.3:
/// "paginação") — purely client-side over the already-fetched, already
/// sorted/filtered rows in memory, never a new fetch; preserves every row
/// already visible.
final class CustomerDashboardRankingPageRequested
    extends CustomerDashboardEvent {
  const CustomerDashboardRankingPageRequested();
}
