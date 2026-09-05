import '../../domain/entities/representative_dashboard_filters.dart';

sealed class RepresentativeDashboardEvent {
  const RepresentativeDashboardEvent();
}

final class RepresentativeDashboardStarted
    extends RepresentativeDashboardEvent {
  const RepresentativeDashboardStarted({
    required this.organizationId,
    required this.requesterUserId,
    required this.initialFilters,
  });

  final String organizationId;
  final String requesterUserId;
  final RepresentativeDashboardFilters initialFilters;
}

final class RepresentativeDashboardFiltersChanged
    extends RepresentativeDashboardEvent {
  const RepresentativeDashboardFiltersChanged(this.filters);
  final RepresentativeDashboardFilters filters;
}

final class RepresentativeDashboardRetried
    extends RepresentativeDashboardEvent {
  const RepresentativeDashboardRetried();
}
