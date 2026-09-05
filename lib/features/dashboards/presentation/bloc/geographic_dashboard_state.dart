import '../../../../core/errors/errors.dart';
import '../../domain/entities/geographic_dashboard_filters.dart';
import '../../domain/entities/geographic_dashboard_snapshot.dart';

enum GeographicDashboardStatus { initial, loading, ready, forbidden, failure }

final class GeographicDashboardState {
  const GeographicDashboardState({
    this.status = GeographicDashboardStatus.initial,
    this.organizationId = '',
    this.userId = '',
    this.filters,
    this.snapshot,
    this.selectedArea,
    this.failure,
  });
  final GeographicDashboardStatus status;
  final String organizationId;
  final String userId;
  final GeographicDashboardFilters? filters;
  final GeographicDashboardSnapshot? snapshot;
  final GeographicDashboardRow? selectedArea;
  final Failure? failure;

  GeographicDashboardState copyWith({
    GeographicDashboardStatus? status,
    GeographicDashboardFilters? filters,
    GeographicDashboardSnapshot? snapshot,
    GeographicDashboardRow? selectedArea,
    Failure? failure,
    bool clearFailure = false,
    bool clearSelection = false,
  }) => GeographicDashboardState(
    status: status ?? this.status,
    organizationId: organizationId,
    userId: userId,
    filters: filters ?? this.filters,
    snapshot: snapshot ?? this.snapshot,
    selectedArea: clearSelection ? null : (selectedArea ?? this.selectedArea),
    failure: clearFailure ? null : (failure ?? this.failure),
  );
}
