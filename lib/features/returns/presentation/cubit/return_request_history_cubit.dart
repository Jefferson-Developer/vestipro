import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/watch_return_requests_for_order_use_case.dart';
import 'return_request_history_state.dart';

/// Feeds the devolução history embedded in the order detail screen
/// (TASK-199/TASK-102) — every `ReturnRequest` linked to one pedido, kept
/// live via [WatchReturnRequestsForOrderUseCase]'s stream.
@injectable
final class ReturnRequestHistoryCubit extends Cubit<ReturnRequestHistoryState> {
  ReturnRequestHistoryCubit(this._watchReturnRequestsForOrder)
    : super(const ReturnRequestHistoryState());

  final WatchReturnRequestsForOrderUseCase _watchReturnRequestsForOrder;
  StreamSubscription<Object?>? _subscription;

  Future<void> watch({
    required String organizationId,
    required String orderId,
  }) async {
    await _subscription?.cancel();
    emit(
      state.copyWith(
        status: ReturnRequestHistoryStatus.loading,
        clearFailureMessage: true,
      ),
    );
    _subscription =
        _watchReturnRequestsForOrder(
          organizationId: organizationId,
          orderId: orderId,
        ).listen((result) {
          result.fold(
            onSuccess: (returnRequests) => emit(
              state.copyWith(
                status: returnRequests.isEmpty
                    ? ReturnRequestHistoryStatus.empty
                    : ReturnRequestHistoryStatus.ready,
                returnRequests: returnRequests,
              ),
            ),
            onFailure: (failure) => emit(
              state.copyWith(
                status: ReturnRequestHistoryStatus.error,
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
