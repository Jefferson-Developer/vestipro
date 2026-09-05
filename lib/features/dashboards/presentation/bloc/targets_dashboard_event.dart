import '../../domain/entities/targets_dashboard_filters.dart';

sealed class TargetsDashboardEvent {
  const TargetsDashboardEvent();
}

final class TargetsDashboardStarted extends TargetsDashboardEvent {
  const TargetsDashboardStarted({
    required this.organizationId,
    required this.userId,
    required this.filters,
  });
  final String organizationId;
  final String userId;
  final TargetsDashboardFilters filters;
}

final class TargetsDashboardFiltersChanged extends TargetsDashboardEvent {
  const TargetsDashboardFiltersChanged(this.filters);
  final TargetsDashboardFilters filters;
}

final class TargetsDashboardDrilledDown extends TargetsDashboardEvent {
  const TargetsDashboardDrilledDown(this.rowId);
  final String rowId;
}

final class TargetsDashboardDrilledUp extends TargetsDashboardEvent {
  const TargetsDashboardDrilledUp();
}

final class TargetsDashboardRetried extends TargetsDashboardEvent {
  const TargetsDashboardRetried();
}
