import '../../domain/entities/target.dart';
import '../../domain/entities/target_progress_view_model.dart';
import '../../domain/entities/target_visibility_filter.dart';
import '../../domain/value_objects/target_dimension_type.dart';
import '../../domain/value_objects/target_metric_type.dart';

enum TargetDashboardStatus {
  initial,
  loading,
  ready,

  /// A Target was found for the selected dimension/period/metric, but its
  /// achievement snapshot has never been calculated server-side yet
  /// (`TargetAchievementSnapshot.isCalculated == false`) — distinct from
  /// [empty], where there is no Target at all to show.
  notCalculated,

  /// No Target exists for the selected dimension/metric at all — never
  /// confused with [notCalculated].
  empty,

  /// The caller is not allowed to view the currently selected
  /// dimension/dimensionId (`TargetVisibilityFilter.canView` denied it, or
  /// resolved to [TargetVisibilityMode.none] entirely).
  forbidden,
  error,
}

/// Drives the achievement dashboard (TASK-116): resolves RBAC visibility,
/// lists the Target periods available for the selected dimension/metric and
/// subscribes to the selected one's near-real-time achievement snapshot.
final class TargetDashboardState {
  const TargetDashboardState({
    this.status = TargetDashboardStatus.initial,
    this.organizationId = '',
    this.companyId = '',
    this.userId = '',
    this.visibilityFilter,
    this.dimensionType = TargetDimensionType.salesRep,
    this.dimensionId = '',
    this.metricType = TargetMetricType.revenue,
    this.candidates = const <Target>[],
    this.selectedTarget,
    this.progress,
    this.failureMessage,
  });

  final TargetDashboardStatus status;
  final String organizationId;
  final String companyId;
  final String userId;

  /// `null` only before `TargetDashboardCubit.load` resolves it for the
  /// first time.
  final TargetVisibilityFilter? visibilityFilter;

  final TargetDimensionType dimensionType;
  final String dimensionId;
  final TargetMetricType metricType;

  /// Every period of [dimensionType]/[dimensionId]/[metricType] the caller
  /// may switch between — the "filtro por período" source.
  final List<Target> candidates;
  final Target? selectedTarget;
  final TargetProgressViewModel? progress;
  final String? failureMessage;

  /// Whether the caller may switch [dimensionType]/[dimensionId] at all — a
  /// `SALES_REP` ([TargetVisibilityMode.ownOnly]) only ever sees their own,
  /// so the dimension picker itself should not even render for them.
  bool get canPickDimension =>
      visibilityFilter?.mode == TargetVisibilityMode.allOrganization ||
      visibilityFilter?.mode == TargetVisibilityMode.teams;

  bool get isBusy => status == TargetDashboardStatus.loading;

  TargetDashboardState copyWith({
    TargetDashboardStatus? status,
    String? organizationId,
    String? companyId,
    String? userId,
    TargetVisibilityFilter? visibilityFilter,
    TargetDimensionType? dimensionType,
    String? dimensionId,
    TargetMetricType? metricType,
    List<Target>? candidates,
    Target? selectedTarget,
    bool clearSelectedTarget = false,
    TargetProgressViewModel? progress,
    bool clearProgress = false,
    String? failureMessage,
    bool clearFailureMessage = false,
  }) {
    return TargetDashboardState(
      status: status ?? this.status,
      organizationId: organizationId ?? this.organizationId,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      visibilityFilter: visibilityFilter ?? this.visibilityFilter,
      dimensionType: dimensionType ?? this.dimensionType,
      dimensionId: dimensionId ?? this.dimensionId,
      metricType: metricType ?? this.metricType,
      candidates: candidates ?? this.candidates,
      selectedTarget: clearSelectedTarget
          ? null
          : (selectedTarget ?? this.selectedTarget),
      progress: clearProgress ? null : (progress ?? this.progress),
      failureMessage: clearFailureMessage
          ? null
          : (failureMessage ?? this.failureMessage),
    );
  }
}
