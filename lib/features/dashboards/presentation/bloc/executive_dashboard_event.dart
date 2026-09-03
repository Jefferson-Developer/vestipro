import '../../domain/entities/executive_dashboard_filters.dart';

sealed class ExecutiveDashboardEvent {
  const ExecutiveDashboardEvent();
}

/// First load of the Executive Dashboard (TASK-134): resolves RBAC scope
/// (`ExecutiveDashboardVisibilityService`), the selectable company/team
/// options and the KPI snapshot for [initialFilters].
final class ExecutiveDashboardStarted extends ExecutiveDashboardEvent {
  const ExecutiveDashboardStarted({
    required this.organizationId,
    required this.userId,
    required this.initialFilters,
  });

  final String organizationId;
  final String userId;
  final ExecutiveDashboardFilters initialFilters;
}

/// The caller changed company/team/month — reloads the KPI snapshot for
/// [filters], re-checking [ExecutiveDashboardVisibilityFilter.canViewCompany]
/// /`canViewTeam` first (never trusting a filter value the UI should not
/// have offered in the first place).
final class ExecutiveDashboardFiltersChanged extends ExecutiveDashboardEvent {
  const ExecutiveDashboardFiltersChanged(this.filters);

  final ExecutiveDashboardFilters filters;
}

/// Re-runs the current [ExecutiveDashboardState.filters] load after a
/// failure.
final class ExecutiveDashboardRetried extends ExecutiveDashboardEvent {
  const ExecutiveDashboardRetried();
}
