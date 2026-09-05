import '../../../../core/errors/errors.dart';
import '../../domain/entities/funnel_dashboard_filters.dart';
import '../../domain/entities/funnel_dashboard_snapshot.dart';
import '../../domain/entities/funnel_dashboard_visibility.dart';

enum FunnelDashboardStatus { initial, loading, ready, forbidden, failure }

final class FunnelDashboardState {
  const FunnelDashboardState({
    this.status = FunnelDashboardStatus.initial,
    this.organizationId = '',
    this.userId = '',
    this.filters,
    this.visibility,
    this.snapshot,
    this.failure,
  });

  final FunnelDashboardStatus status;
  final String organizationId;
  final String userId;
  final FunnelDashboardFilters? filters;
  final FunnelDashboardVisibility? visibility;
  final FunnelDashboardSnapshot? snapshot;
  final Failure? failure;

  FunnelDashboardState copyWith({
    FunnelDashboardStatus? status,
    String? organizationId,
    String? userId,
    FunnelDashboardFilters? filters,
    FunnelDashboardVisibility? visibility,
    FunnelDashboardSnapshot? snapshot,
    Failure? failure,
    bool clearFailure = false,
  }) => FunnelDashboardState(
    status: status ?? this.status,
    organizationId: organizationId ?? this.organizationId,
    userId: userId ?? this.userId,
    filters: filters ?? this.filters,
    visibility: visibility ?? this.visibility,
    snapshot: snapshot ?? this.snapshot,
    failure: clearFailure ? null : (failure ?? this.failure),
  );
}
