import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../domain/entities/demand_forecast.dart';
import '../../domain/usecases/get_demand_forecast_use_case.dart';
import 'demand_forecast_event.dart';
import 'demand_forecast_state.dart';

/// Drives the tela de previsão de demanda (TASK-185, EPIC-27) — a single
/// escopo/filtro query + chart, unlike `ReplenishmentSuggestionsBloc`
/// (TASK-184)'s paginated list, since a `DemandForecast` is looked up one
/// produto/coleção/região at a time.
@injectable
final class DemandForecastBloc
    extends Bloc<DemandForecastEvent, DemandForecastState> {
  DemandForecastBloc({required this.getForecast})
    : super(const DemandForecastState()) {
    on<DemandForecastRequested>(_onRequested, transformer: restartable());
    on<DemandForecastRefreshRequested>(
      _onRefreshRequested,
      transformer: restartable(),
    );
  }

  final GetDemandForecastUseCase getForecast;

  Future<void> _onRequested(
    DemandForecastRequested event,
    Emitter<DemandForecastState> emit,
  ) async {
    emit(
      state.copyWith(
        loadStatus: DemandForecastLoadStatus.loading,
        organizationId: event.organizationId,
        companyId: event.companyId,
        userId: event.userId,
        scopeType: event.scopeType,
        scopeId: event.scopeId,
        clearForecast: true,
        clearFailure: true,
      ),
    );
    await _load(emit);
  }

  Future<void> _onRefreshRequested(
    DemandForecastRefreshRequested event,
    Emitter<DemandForecastState> emit,
  ) async {
    if (state.organizationId.isEmpty || state.scopeId.isEmpty) return;
    emit(
      state.copyWith(
        loadStatus: DemandForecastLoadStatus.loading,
        clearFailure: true,
      ),
    );
    await _load(emit);
  }

  Future<void> _load(Emitter<DemandForecastState> emit) async {
    final result = await getForecast(
      organizationId: state.organizationId,
      companyId: state.companyId,
      requestedByUserId: state.userId,
      scopeType: state.scopeType,
      scopeId: state.scopeId,
    );
    if (emit.isDone) return;

    switch (result) {
      case AppSuccess<DemandForecast?>(value: final forecast):
        emit(
          state.copyWith(
            loadStatus: DemandForecastLoadStatus.ready,
            forecast: forecast,
            clearForecast: forecast == null,
            clearFailure: true,
          ),
        );
      case AppFailure<DemandForecast?>(failure: final failure):
        emit(
          state.copyWith(
            loadStatus: DemandForecastLoadStatus.failure,
            clearForecast: true,
            failure: failure,
          ),
        );
    }
  }
}
