import 'package:bloc/bloc.dart';
// `injectable` also exports an `Order` annotation (unrelated to this
// feature's `Order` entity) — hidden here, same precedent `OrderDraftBloc`
// already follows.
import 'package:injectable/injectable.dart' hide Order;

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_pricing_summary.dart';
import '../../domain/usecases/get_order_pricing_summary_use_case.dart';
import 'order_pricing_summary_state.dart';

/// Owns the order draft's commercial summary card lifecycle (EPIC-13,
/// TASK-099): every time [recalculate] is called with the draft's current
/// [Order], it asks [GetOrderPricingSummaryUseCase] — and only that use
/// case — for subtotal/desconto/acréscimo/frete/total, never computing any
/// of those itself.
///
/// Deliberately its own cubit (not folded into `OrderDraftBloc`): pricing is
/// a slower, network-bound recalculation that must never block the seller
/// from continuing to edit quantities while it is in flight — the same
/// "cada preocupação, seu próprio cubit" precedent `OrderItemsGridCubit`
/// already sets for this screen. `OrderDraftBloc` stays the single source of
/// truth for the actual `OrderItem`s; this cubit only answers "what does the
/// pricing engine say about them right now".
@injectable
final class OrderPricingSummaryCubit extends Cubit<OrderPricingSummaryState> {
  OrderPricingSummaryCubit(this._getOrderPricingSummary)
    : super(const OrderPricingSummaryState());

  final GetOrderPricingSummaryUseCase _getOrderPricingSummary;

  /// Guards against a stale response overwriting a newer one — the same
  /// token-based staleness guard `OrderDraftBloc._autoSaveToken` already
  /// uses, needed here because [recalculate] is expected to be called again
  /// (debounced by the caller) before a previous call's response arrives.
  int _requestToken = 0;

  Future<void> recalculate(Order order) async {
    if (order.items.isEmpty) {
      _requestToken++;
      emit(const OrderPricingSummaryState());
      return;
    }

    final token = ++_requestToken;
    emit(
      state.copyWith(
        status: OrderPricingSummaryStatus.recalculating,
        clearFailure: true,
      ),
    );

    final result = await _getOrderPricingSummary(order: order);
    if (isClosed || token != _requestToken) return;

    switch (result) {
      case AppSuccess<OrderPricingSummary>(value: final summary):
        emit(
          OrderPricingSummaryState(
            status: OrderPricingSummaryStatus.success,
            summary: summary,
          ),
        );
      case AppFailure<OrderPricingSummary>(failure: final failure):
        final isOffline = failure is ConnectivityFailure;
        emit(
          OrderPricingSummaryState(
            status: isOffline
                ? OrderPricingSummaryStatus.offlineEstimate
                : OrderPricingSummaryStatus.failure,
            // The last confirmed summary (if any) is deliberately dropped
            // here, never shown side-by-side with a stale label — the
            // offline estimate below is the only figure shown until a fresh
            // one is confirmed.
            localEstimateSubtotal: isOffline ? order.itemsSubtotal : null,
            localEstimateShippingAmount: isOffline
                ? order.shippingAmount
                : null,
            failure: failure,
          ),
        );
    }
  }
}
