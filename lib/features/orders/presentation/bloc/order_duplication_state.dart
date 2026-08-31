import '../../../../core/errors/errors.dart';
import '../../domain/entities/order_duplication_result.dart';

enum OrderDuplicationStatus { idle, submitting, success, failure }

/// Drives "Repetir pedido" (TASK-104) — a one-shot action, same shape
/// `OrderProductAdditionState` already establishes for a single async
/// use-case call driving one screen's own submit button.
final class OrderDuplicationState {
  const OrderDuplicationState({
    this.status = OrderDuplicationStatus.idle,
    this.result,
    this.failure,
  });

  final OrderDuplicationStatus status;
  final OrderDuplicationResult? result;
  final Failure? failure;

  OrderDuplicationState copyWith({
    OrderDuplicationStatus? status,
    OrderDuplicationResult? result,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return OrderDuplicationState(
      status: status ?? this.status,
      result: result ?? this.result,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }
}
