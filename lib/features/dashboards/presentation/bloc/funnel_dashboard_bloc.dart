import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/funnel_dashboard_snapshot.dart';
import '../../domain/usecases/load_funnel_dashboard_use_case.dart';
import 'funnel_dashboard_event.dart';
import 'funnel_dashboard_state.dart';

@injectable
final class FunnelDashboardBloc
    extends Bloc<FunnelDashboardEvent, FunnelDashboardState> {
  FunnelDashboardBloc(this._loadDashboard, this._analytics)
    : super(const FunnelDashboardState()) {
    on<FunnelDashboardStarted>(_onStarted);
    on<FunnelDashboardFiltersChanged>(_onFiltersChanged);
    on<FunnelDashboardRetried>(_onRetried);
  }

  final LoadFunnelDashboardUseCase _loadDashboard;
  final AnalyticsService _analytics;

  Future<void> _onStarted(
    FunnelDashboardStarted event,
    Emitter<FunnelDashboardState> emit,
  ) async {
    emit(
      FunnelDashboardState(
        status: FunnelDashboardStatus.loading,
        organizationId: event.organizationId,
        userId: event.userId,
        filters: event.filters,
      ),
    );
    await _load(emit);
  }

  Future<void> _onFiltersChanged(
    FunnelDashboardFiltersChanged event,
    Emitter<FunnelDashboardState> emit,
  ) async {
    emit(
      state.copyWith(
        status: FunnelDashboardStatus.loading,
        filters: event.filters,
        clearFailure: true,
      ),
    );
    await _load(emit);
  }

  Future<void> _onRetried(
    FunnelDashboardRetried event,
    Emitter<FunnelDashboardState> emit,
  ) async {
    emit(
      state.copyWith(status: FunnelDashboardStatus.loading, clearFailure: true),
    );
    await _load(emit);
  }

  Future<void> _load(Emitter<FunnelDashboardState> emit) async {
    final filters = state.filters!;
    final result = await _loadDashboard(
      organizationId: state.organizationId,
      userId: state.userId,
      filters: filters,
    );
    switch (result) {
      case AppFailure<FunnelDashboardSnapshot>(failure: final failure):
        emit(
          state.copyWith(
            status: failure is PermissionFailure
                ? FunnelDashboardStatus.forbidden
                : FunnelDashboardStatus.failure,
            failure: failure,
          ),
        );
      case AppSuccess<FunnelDashboardSnapshot>(value: final snapshot):
        emit(
          state.copyWith(
            status: FunnelDashboardStatus.ready,
            snapshot: snapshot,
            clearFailure: true,
          ),
        );
        unawaited(
          _analytics.logEvent(
            AnalyticsEvents.dashboardViewed,
            parameters: <String, Object?>{
              'organization_id': state.organizationId,
              'dashboard_type': 'funnel',
              'company_id': filters.companyId,
              'team_id': filters.teamId,
              'seller_id': filters.sellerId,
              'month': filters.monthKey,
            },
          ),
        );
    }
  }
}
