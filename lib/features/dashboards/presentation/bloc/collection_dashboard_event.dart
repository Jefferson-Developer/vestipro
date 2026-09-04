import '../../domain/entities/collection_dashboard_filters.dart';

sealed class CollectionDashboardEvent {
  const CollectionDashboardEvent();
}

/// First load of the Collection Dashboard (TASK-138): resolves RBAC scope
/// (`ExecutiveDashboardVisibilityService`, reused verbatim — same rationale
/// `ProductDashboardBloc`/`CustomerDashboardBloc` already document), the
/// selectable company/coleção options and the comparison entries for
/// [initialFilters].
final class CollectionDashboardStarted extends CollectionDashboardEvent {
  const CollectionDashboardStarted({
    required this.organizationId,
    required this.userId,
    required this.initialFilters,
  });

  final String organizationId;
  final String userId;
  final CollectionDashboardFilters initialFilters;
}

/// The caller changed the company scope or the set of Collections being
/// compared — reloads the comparison entries for [filters], re-checking
/// `ExecutiveDashboardVisibilityFilter.canViewCompany` first (never trusting
/// a filter value the UI should not have offered).
final class CollectionDashboardFiltersChanged extends CollectionDashboardEvent {
  const CollectionDashboardFiltersChanged(this.filters);

  final CollectionDashboardFilters filters;
}

/// Re-runs the current filters' full load after a failure.
final class CollectionDashboardRetried extends CollectionDashboardEvent {
  const CollectionDashboardRetried();
}
