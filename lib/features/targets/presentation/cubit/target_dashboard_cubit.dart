import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/target.dart';
import '../../domain/entities/target_achievement_snapshot.dart';
import '../../domain/entities/target_progress_view_model.dart';
import '../../domain/entities/target_visibility_filter.dart';
import '../../domain/repositories/target_achievement_repository.dart';
import '../../domain/repositories/target_repository.dart';
import '../../domain/services/target_visibility_service.dart';
import '../../domain/value_objects/target_dimension_type.dart';
import '../../domain/value_objects/target_metric_type.dart';
import 'target_dashboard_state.dart';

/// Drives the achievement dashboard (TASK-116, EPIC-15): resolves which
/// dimension(s) the caller may view (`TargetVisibilityService`, never
/// trusted from the UI alone), lists the `Target` periods available for the
/// selected dimension/metric (`TargetRepository.listByDimension`, the same
/// contract `TargetFormCubit` already reuses) and subscribes to the selected
/// period's near-real-time achievement snapshot
/// (`TargetAchievementRepository.watchForTarget`), recomputing
/// `TargetProgressViewModel.compute` — the only place gap/atingimento/
/// projeção are calculated — on every tick.
@injectable
final class TargetDashboardCubit extends Cubit<TargetDashboardState> {
  TargetDashboardCubit(
    this._visibilityService,
    this._targetRepository,
    this._achievementRepository,
    this._analyticsService,
  ) : super(const TargetDashboardState());

  final TargetVisibilityService _visibilityService;
  final TargetRepository _targetRepository;
  final TargetAchievementRepository _achievementRepository;
  final AnalyticsService _analyticsService;

  StreamSubscription<TargetAchievementSnapshot>? _achievementSubscription;

  /// Resolves visibility and loads the caller's own `salesRep` dimension by
  /// default — the "minha meta" landing view every role that can reach this
  /// page at all is guaranteed to be allowed to see.
  Future<void> load({
    required String organizationId,
    required String companyId,
    required String userId,
  }) async {
    emit(
      state.copyWith(
        status: TargetDashboardStatus.loading,
        organizationId: organizationId,
        companyId: companyId,
        userId: userId,
      ),
    );

    final filterResult = await _visibilityService.resolve(
      organizationId: organizationId,
      companyId: companyId,
      userId: userId,
    );

    if (filterResult case AppFailure<TargetVisibilityFilter>(
      failure: final failure,
    )) {
      emit(
        state.copyWith(
          status: TargetDashboardStatus.error,
          failureMessage: failure.message,
        ),
      );
      return;
    }
    final filter = (filterResult as AppSuccess<TargetVisibilityFilter>).value;
    emit(state.copyWith(visibilityFilter: filter));

    if (!filter.canViewAny) {
      emit(state.copyWith(status: TargetDashboardStatus.forbidden));
      return;
    }

    await selectDimension(
      dimensionType: TargetDimensionType.salesRep,
      dimensionId: userId,
      metricType: state.metricType,
    );
  }

  /// Switches the dashboard to [dimensionType]/[dimensionId] (the "filtro
  /// por dimensão"), re-checking [TargetVisibilityFilter.canView] first —
  /// never assuming the UI already hid an option the caller cannot reach.
  Future<void> selectDimension({
    required TargetDimensionType dimensionType,
    required String dimensionId,
    TargetMetricType? metricType,
  }) async {
    final filter = state.visibilityFilter;
    final trimmedDimensionId = dimensionId.trim();
    if (filter == null || trimmedDimensionId.isEmpty) return;

    final effectiveMetric = metricType ?? state.metricType;

    if (!filter.canView(
      dimensionType: dimensionType,
      dimensionId: trimmedDimensionId,
    )) {
      await _achievementSubscription?.cancel();
      _achievementSubscription = null;
      emit(
        state.copyWith(
          status: TargetDashboardStatus.forbidden,
          dimensionType: dimensionType,
          dimensionId: trimmedDimensionId,
          metricType: effectiveMetric,
          candidates: const <Target>[],
          clearSelectedTarget: true,
          clearProgress: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: TargetDashboardStatus.loading,
        dimensionType: dimensionType,
        dimensionId: trimmedDimensionId,
        metricType: effectiveMetric,
      ),
    );

    final result = await _targetRepository.listByDimension(
      organizationId: state.organizationId,
      companyId: state.companyId,
      dimensionType: dimensionType,
      dimensionId: trimmedDimensionId,
      metricType: effectiveMetric,
    );

    switch (result) {
      case AppFailure<List<Target>>(failure: final failure):
        emit(
          state.copyWith(
            status: TargetDashboardStatus.error,
            failureMessage: failure.message,
          ),
        );
        return;
      case AppSuccess<List<Target>>(value: final targets):
        final candidates =
            targets.where((target) => target.deletedAt == null).toList()
              ..sort((a, b) => a.startDate.compareTo(b.startDate));
        emit(state.copyWith(candidates: candidates));

        unawaited(
          _analyticsService.logEvent(
            AnalyticsEvents.targetDashboardViewed,
            parameters: <String, Object?>{
              'organization_id': state.organizationId,
              'company_id': state.companyId,
              'dimension_type': dimensionType.name,
              'metric_type': effectiveMetric.name,
            },
          ),
        );

        final defaultTarget = _pickDefaultTarget(candidates);
        if (defaultTarget == null) {
          emit(
            state.copyWith(
              status: TargetDashboardStatus.empty,
              clearSelectedTarget: true,
              clearProgress: true,
            ),
          );
          return;
        }
        await selectPeriod(defaultTarget);
    }
  }

  /// Switches to a specific already-listed [target] (the "filtro por
  /// período"), re-subscribing to its own achievement stream.
  Future<void> selectPeriod(Target target) async {
    await _achievementSubscription?.cancel();

    emit(
      state.copyWith(
        status: TargetDashboardStatus.loading,
        selectedTarget: target,
        clearProgress: true,
      ),
    );

    _achievementSubscription = _achievementRepository
        .watchForTarget(
          organizationId: target.organizationId,
          targetId: target.id,
        )
        .listen(
          _onAchievement,
          onError: (Object error) {
            emit(
              state.copyWith(
                status: TargetDashboardStatus.error,
                failureMessage: error.toString(),
              ),
            );
          },
        );
  }

  void _onAchievement(TargetAchievementSnapshot snapshot) {
    final target = state.selectedTarget;
    if (target == null || target.id != snapshot.targetId) return;

    if (!snapshot.isCalculated) {
      emit(
        state.copyWith(
          status: TargetDashboardStatus.notCalculated,
          clearProgress: true,
        ),
      );
      return;
    }

    final progress = TargetProgressViewModel.compute(
      target: target,
      realizedValue: snapshot.realizedValue!,
      calculatedAt: snapshot.calculatedAt,
      now: DateTime.now().toUtc(),
    );
    emit(
      state.copyWith(status: TargetDashboardStatus.ready, progress: progress),
    );
  }

  /// Picks the period a caller most likely wants to see by default: the one
  /// currently in progress, else the most recently ended one, else the
  /// soonest upcoming one.
  Target? _pickDefaultTarget(List<Target> candidates) {
    if (candidates.isEmpty) return null;
    final now = DateTime.now().toUtc();

    for (final target in candidates) {
      if (!now.isBefore(target.startDate) && now.isBefore(target.endDate)) {
        return target;
      }
    }

    Target? mostRecentlyEnded;
    for (final target in candidates) {
      if (!now.isBefore(target.endDate)) {
        mostRecentlyEnded = target;
      }
    }
    if (mostRecentlyEnded != null) return mostRecentlyEnded;

    return candidates.first;
  }

  @override
  Future<void> close() {
    unawaited(_achievementSubscription?.cancel());
    return super.close();
  }
}
