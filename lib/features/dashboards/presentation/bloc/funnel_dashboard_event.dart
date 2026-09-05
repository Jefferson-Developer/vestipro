import '../../domain/entities/funnel_dashboard_filters.dart';

sealed class FunnelDashboardEvent {
  const FunnelDashboardEvent();
}

final class FunnelDashboardStarted extends FunnelDashboardEvent {
  const FunnelDashboardStarted({
    required this.organizationId,
    required this.userId,
    required this.filters,
  });

  final String organizationId;
  final String userId;
  final FunnelDashboardFilters filters;
}

final class FunnelDashboardFiltersChanged extends FunnelDashboardEvent {
  const FunnelDashboardFiltersChanged(this.filters);
  final FunnelDashboardFilters filters;
}

final class FunnelDashboardRetried extends FunnelDashboardEvent {
  const FunnelDashboardRetried();
}
