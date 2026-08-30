import '../../../../core/errors/errors.dart';

enum OrderItemsCounterStatus { initial, loading, ready, failure }

/// State of `OrderItemsCounterCubit` (TASK-097) — the "produtos no pedido
/// atual" indicator shown while browsing the catalog from inside the "novo
/// pedido" flow.
final class OrderItemsCounterState {
  const OrderItemsCounterState({
    this.status = OrderItemsCounterStatus.initial,
    this.itemCount = 0,
    this.failure,
  });

  final OrderItemsCounterStatus status;
  final int itemCount;
  final Failure? failure;

  bool get hasItems => itemCount > 0;

  OrderItemsCounterState copyWith({
    OrderItemsCounterStatus? status,
    int? itemCount,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return OrderItemsCounterState(
      status: status ?? this.status,
      itemCount: itemCount ?? this.itemCount,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}
