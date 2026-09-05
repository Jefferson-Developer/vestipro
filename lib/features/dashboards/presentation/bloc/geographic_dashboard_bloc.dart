import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/geographic_dashboard_snapshot.dart';
import '../../domain/usecases/load_geographic_dashboard_use_case.dart';
import 'geographic_dashboard_event.dart';
import 'geographic_dashboard_state.dart';

@injectable
final class GeographicDashboardBloc
    extends Bloc<GeographicDashboardEvent, GeographicDashboardState> {
  GeographicDashboardBloc(this._load, this._analytics)
    : super(const GeographicDashboardState()) {
    on<GeographicDashboardStarted>(_onStarted);
    on<GeographicDashboardFiltersChanged>(_onFiltersChanged);
    on<GeographicDashboardDrillDownRequested>(
      (event, emit) => emit(state.copyWith(selectedArea: event.row)),
    );
    on<GeographicDashboardRetried>((event, emit) => _fetch(emit));
  }
  final LoadGeographicDashboardUseCase _load;
  final AnalyticsService _analytics;

  Future<void> _onStarted(
    GeographicDashboardStarted event,
    Emitter<GeographicDashboardState> emit,
  ) async {
    emit(
      GeographicDashboardState(
        status: GeographicDashboardStatus.loading,
        organizationId: event.organizationId,
        userId: event.userId,
        filters: event.filters,
      ),
    );
    await _fetch(emit);
  }

  Future<void> _onFiltersChanged(
    GeographicDashboardFiltersChanged event,
    Emitter<GeographicDashboardState> emit,
  ) async {
    emit(
      state.copyWith(
        status: GeographicDashboardStatus.loading,
        filters: event.filters,
        clearFailure: true,
        clearSelection: true,
      ),
    );
    await _fetch(emit);
  }

  Future<void> _fetch(Emitter<GeographicDashboardState> emit) async {
    emit(
      state.copyWith(
        status: GeographicDashboardStatus.loading,
        clearFailure: true,
      ),
    );
    final filters = state.filters!;
    final result = await _load(
      organizationId: state.organizationId,
      userId: state.userId,
      filters: filters,
    );
    switch (result) {
      case AppFailure<GeographicDashboardSnapshot>(failure: final failure):
        emit(
          state.copyWith(
            status: failure is PermissionFailure
                ? GeographicDashboardStatus.forbidden
                : GeographicDashboardStatus.failure,
            failure: failure,
          ),
        );
      case AppSuccess<GeographicDashboardSnapshot>(value: final snapshot):
        emit(
          state.copyWith(
            status: GeographicDashboardStatus.ready,
            snapshot: snapshot,
            clearFailure: true,
          ),
        );
        unawaited(
          _analytics.logEvent(
            AnalyticsEvents.dashboardViewed,
            parameters: <String, Object?>{
              'organization_id': state.organizationId,
              'dashboard_type': 'geographic',
              'company_id': filters.companyId,
              'month': filters.monthKey,
            },
          ),
        );
    }
  }
}
