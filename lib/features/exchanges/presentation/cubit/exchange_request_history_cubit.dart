import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/watch_exchange_requests_for_order_use_case.dart';
import 'exchange_request_history_state.dart';

/// Feeds the troca history embedded in the order detail screen
/// (TASK-200/TASK-102) — every `ExchangeRequest` linked to one pedido, kept
/// live via [WatchExchangeRequestsForOrderUseCase]'s stream.
@injectable
final class ExchangeRequestHistoryCubit
    extends Cubit<ExchangeRequestHistoryState> {
  ExchangeRequestHistoryCubit(this._watchExchangeRequestsForOrder)
    : super(const ExchangeRequestHistoryState());

  final WatchExchangeRequestsForOrderUseCase _watchExchangeRequestsForOrder;
  StreamSubscription<Object?>? _subscription;

  Future<void> watch({
    required String organizationId,
    required String orderId,
  }) async {
    await _subscription?.cancel();
    emit(
      state.copyWith(
        status: ExchangeRequestHistoryStatus.loading,
        clearFailureMessage: true,
      ),
    );
    _subscription =
        _watchExchangeRequestsForOrder(
          organizationId: organizationId,
          orderId: orderId,
        ).listen((result) {
          result.fold(
            onSuccess: (exchangeRequests) => emit(
              state.copyWith(
                status: exchangeRequests.isEmpty
                    ? ExchangeRequestHistoryStatus.empty
                    : ExchangeRequestHistoryStatus.ready,
                exchangeRequests: exchangeRequests,
              ),
            ),
            onFailure: (failure) => emit(
              state.copyWith(
                status: ExchangeRequestHistoryStatus.error,
                failureMessage: failure.message,
              ),
            ),
          );
        });
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
