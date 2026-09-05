import '../../domain/entities/geographic_dashboard_filters.dart';
import '../../domain/entities/geographic_dashboard_snapshot.dart';

sealed class GeographicDashboardEvent {
  const GeographicDashboardEvent();
}

final class GeographicDashboardStarted extends GeographicDashboardEvent {
  const GeographicDashboardStarted({
    required this.organizationId,
    required this.userId,
    required this.filters,
  });
  final String organizationId;
  final String userId;
  final GeographicDashboardFilters filters;
}

final class GeographicDashboardFiltersChanged extends GeographicDashboardEvent {
  const GeographicDashboardFiltersChanged(this.filters);
  final GeographicDashboardFilters filters;
}

final class GeographicDashboardDrillDownRequested
    extends GeographicDashboardEvent {
  const GeographicDashboardDrillDownRequested(this.row);
  final GeographicDashboardRow row;
}

final class GeographicDashboardRetried extends GeographicDashboardEvent {
  const GeographicDashboardRetried();
}
