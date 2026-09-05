import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/representative_dashboard_filters.dart';
import '../../domain/entities/representative_dashboard_snapshot.dart';
import '../../domain/usecases/load_representative_dashboard_use_case.dart';
import 'representative_dashboard_event.dart';
import 'representative_dashboard_state.dart';

@injectable
final class RepresentativeDashboardBloc
    extends Bloc<RepresentativeDashboardEvent, RepresentativeDashboardState> {
  RepresentativeDashboardBloc(this._loadDashboard, this._analyticsService)
    : super(const RepresentativeDashboardState()) {
    on<RepresentativeDashboardStarted>(_onStarted);
    on<RepresentativeDashboardFiltersChanged>(_onFiltersChanged);
    on<RepresentativeDashboardRetried>(_onRetried);
  }

  final LoadRepresentativeDashboardUseCase _loadDashboard;
  final AnalyticsService _analyticsService;

  Future<void> _onStarted(
    RepresentativeDashboardStarted event,
    Emitter<RepresentativeDashboardState> emit,
  ) async {
    emit(
      RepresentativeDashboardState(
        status: RepresentativeDashboardStatus.loading,
        organizationId: event.organizationId,
        requesterUserId: event.requesterUserId,
        filters: event.initialFilters,
      ),
    );
    await _load(event.initialFilters, emit);
  }

  Future<void> _onFiltersChanged(
    RepresentativeDashboardFiltersChanged event,
    Emitter<RepresentativeDashboardState> emit,
  ) async {
    emit(
      state.copyWith(
        status: RepresentativeDashboardStatus.loading,
        filters: event.filters,
        clearFailure: true,
      ),
    );
    await _load(event.filters, emit);
  }

  Future<void> _onRetried(
    RepresentativeDashboardRetried event,
    Emitter<RepresentativeDashboardState> emit,
  ) async {
    emit(
      state.copyWith(
        status: RepresentativeDashboardStatus.loading,
        clearFailure: true,
      ),
    );
    await _load(state.filters, emit);
  }

  Future<void> _load(
    RepresentativeDashboardFilters filters,
    Emitter<RepresentativeDashboardState> emit,
  ) async {
    final result = await _loadDashboard(
      organizationId: state.organizationId,
      requesterUserId: state.requesterUserId,
      filters: filters,
    );
    if (emit.isDone) return;
    switch (result) {
      case AppFailure<RepresentativeDashboardSnapshot>(failure: final failure):
        emit(
          state.copyWith(
            status: failure is PermissionFailure
                ? RepresentativeDashboardStatus.forbidden
                : RepresentativeDashboardStatus.error,
            failure: failure,
          ),
        );
      case AppSuccess<RepresentativeDashboardSnapshot>(value: final snapshot):
        emit(
          state.copyWith(
            status: RepresentativeDashboardStatus.ready,
            snapshot: snapshot,
            clearFailure: true,
          ),
        );
        unawaited(
          _analyticsService.logEvent(
            AnalyticsEvents.dashboardViewed,
            parameters: <String, Object?>{
              'organization_id': state.organizationId,
              'dashboard_type': 'representative',
              'company_id': filters.companyId,
              'seller_id': filters.sellerId,
              'month': filters.monthKey,
              'from_local_cache': snapshot.isFromLocalCache,
            },
          ),
        );
    }
  }
}
