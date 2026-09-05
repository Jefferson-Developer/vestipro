import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/targets_dashboard_filters.dart';
import '../../domain/entities/targets_dashboard_snapshot.dart';
import '../../domain/usecases/load_targets_dashboard_use_case.dart';
import 'targets_dashboard_event.dart';
import 'targets_dashboard_state.dart';

@injectable
final class TargetsDashboardBloc
    extends Bloc<TargetsDashboardEvent, TargetsDashboardState> {
  TargetsDashboardBloc(this._loadDashboard, this._analytics)
    : super(const TargetsDashboardState()) {
    on<TargetsDashboardStarted>(_onStarted);
    on<TargetsDashboardFiltersChanged>(_onFiltersChanged);
    on<TargetsDashboardDrilledDown>(_onDrilledDown);
    on<TargetsDashboardDrilledUp>(_onDrilledUp);
    on<TargetsDashboardRetried>(_onRetried);
  }

  final LoadTargetsDashboardUseCase _loadDashboard;
  final AnalyticsService _analytics;

  Future<void> _onStarted(
    TargetsDashboardStarted event,
    Emitter<TargetsDashboardState> emit,
  ) async {
    emit(
      TargetsDashboardState(
        status: TargetsDashboardStatus.loading,
        organizationId: event.organizationId,
        userId: event.userId,
        filters: event.filters,
      ),
    );
    await _load(event.filters, emit);
  }

  Future<void> _onFiltersChanged(
    TargetsDashboardFiltersChanged event,
    Emitter<TargetsDashboardState> emit,
  ) async {
    emit(
      state.copyWith(
        status: TargetsDashboardStatus.loading,
        filters: event.filters,
        drillPath: const <String>[],
        clearFailure: true,
      ),
    );
    await _load(event.filters, emit);
  }

  void _onDrilledDown(
    TargetsDashboardDrilledDown event,
    Emitter<TargetsDashboardState> emit,
  ) {
    final current = state.drilledRow;
    if (current?.children.any((row) => row.id == event.rowId) != true) return;
    emit(state.copyWith(drillPath: <String>[...state.drillPath, event.rowId]));
  }

  void _onDrilledUp(
    TargetsDashboardDrilledUp event,
    Emitter<TargetsDashboardState> emit,
  ) {
    if (state.drillPath.isEmpty) return;
    emit(
      state.copyWith(
        drillPath: state.drillPath.sublist(0, state.drillPath.length - 1),
      ),
    );
  }

  Future<void> _onRetried(
    TargetsDashboardRetried event,
    Emitter<TargetsDashboardState> emit,
  ) async {
    emit(
      state.copyWith(
        status: TargetsDashboardStatus.loading,
        clearFailure: true,
      ),
    );
    await _load(state.filters, emit);
  }

  Future<void> _load(
    TargetsDashboardFilters filters,
    Emitter<TargetsDashboardState> emit,
  ) async {
    final result = await _loadDashboard(
      organizationId: state.organizationId,
      userId: state.userId,
      filters: filters,
    );
    if (emit.isDone) return;
    switch (result) {
      case AppFailure<TargetsDashboardSnapshot>(failure: final failure):
        emit(
          state.copyWith(
            status: failure is PermissionFailure
                ? TargetsDashboardStatus.forbidden
                : TargetsDashboardStatus.error,
            failure: failure,
          ),
        );
      case AppSuccess<TargetsDashboardSnapshot>(value: final snapshot):
        emit(
          state.copyWith(
            status: TargetsDashboardStatus.ready,
            snapshot: snapshot,
            clearFailure: true,
          ),
        );
        unawaited(
          _analytics.logEvent(
            AnalyticsEvents.dashboardViewed,
            parameters: <String, Object?>{
              'organization_id': state.organizationId,
              'company_id': filters.companyId,
              'dashboard_type': 'targets',
              'team_id': filters.teamId,
              'seller_id': filters.sellerId,
              'month': filters.monthKey,
            },
          ),
        );
    }
  }
}
