import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

import '../../../../core/utils/utils.dart';
import '../../domain/entities/stock_alert_page.dart';
import '../../domain/entities/stock_alert.dart';
import '../../domain/usecases/list_stock_alerts_use_case.dart';
import 'stock_alert_list_event.dart';
import 'stock_alert_list_state.dart';

final class StockAlertListBloc
    extends Bloc<StockAlertListEvent, StockAlertListState> {
  StockAlertListBloc({required this.listStockAlerts})
    : super(const StockAlertListState()) {
    on<StockAlertListStarted>(_onStarted, transformer: restartable());
    on<StockAlertListRefreshRequested>(
      _onRefreshRequested,
      transformer: restartable(),
    );
    on<StockAlertListFiltersApplied>(
      _onFiltersApplied,
      transformer: restartable(),
    );
    on<StockAlertListFiltersCleared>(
      _onFiltersCleared,
      transformer: restartable(),
    );
  }

  final ListStockAlertsUseCase listStockAlerts;

  Future<void> _onStarted(
    StockAlertListStarted event,
    Emitter<StockAlertListState> emit,
  ) async {
    final next = state.copyWith(
      loadStatus: StockAlertListLoadStatus.loading,
      organizationId: event.organizationId,
      userId: event.userId,
      alerts: const <StockAlert>[],
      clearLoadFailure: true,
    );
    emit(next);
    await _load(next, emit);
  }

  Future<void> _onRefreshRequested(
    StockAlertListRefreshRequested event,
    Emitter<StockAlertListState> emit,
  ) async {
    if (state.organizationId.isEmpty || state.userId.isEmpty) return;
    final next = state.copyWith(
      loadStatus: StockAlertListLoadStatus.loading,
      alerts: const <StockAlert>[],
      clearLoadFailure: true,
    );
    emit(next);
    await _load(next, emit);
  }

  Future<void> _onFiltersApplied(
    StockAlertListFiltersApplied event,
    Emitter<StockAlertListState> emit,
  ) async {
    final next = state.copyWith(
      loadStatus: StockAlertListLoadStatus.loading,
      alerts: const <StockAlert>[],
      level: event.level,
      productId: event.productId.trim(),
      warehouseId: event.warehouseId.trim(),
      clearLevel: event.level == null,
      clearLoadFailure: true,
    );
    emit(next);
    await _load(next, emit);
  }

  Future<void> _onFiltersCleared(
    StockAlertListFiltersCleared event,
    Emitter<StockAlertListState> emit,
  ) async {
    final next = state.copyWith(
      loadStatus: StockAlertListLoadStatus.loading,
      alerts: const <StockAlert>[],
      clearLevel: true,
      clearProductId: true,
      clearWarehouseId: true,
      clearLoadFailure: true,
    );
    emit(next);
    await _load(next, emit);
  }

  Future<void> _load(
    StockAlertListState request,
    Emitter<StockAlertListState> emit,
  ) async {
    final result = await listStockAlerts(
      organizationId: request.organizationId,
      requestedByUserId: request.userId,
      limit: kStockAlertPageSize,
      level: request.level,
      productId: request.productId,
      warehouseId: request.warehouseId,
    );

    if (emit.isDone) return;

    switch (result) {
      case AppSuccess<StockAlertPage>(value: final page):
        emit(
          state.copyWith(
            loadStatus: StockAlertListLoadStatus.ready,
            alerts: page.alerts,
            clearLoadFailure: true,
          ),
        );
      case AppFailure<StockAlertPage>(failure: final failure):
        emit(
          state.copyWith(
            loadStatus: StockAlertListLoadStatus.failure,
            alerts: const <StockAlert>[],
            loadFailure: failure,
          ),
        );
    }
  }
}
