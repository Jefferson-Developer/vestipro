import '../../../../core/errors/errors.dart';

enum OrderProductAdditionStatus { idle, submitting, success, failure }

/// State of `OrderProductAdditionCubit` (TASK-097) — orchestrates persisting
/// the variants/quantities picked on the catalog's product detail screen
/// into an existing `Order` draft.
final class OrderProductAdditionState {
  const OrderProductAdditionState({
    this.status = OrderProductAdditionStatus.idle,
    this.failure,
  });

  final OrderProductAdditionStatus status;
  final Failure? failure;

  OrderProductAdditionState copyWith({
    OrderProductAdditionStatus? status,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return OrderProductAdditionState(
      status: status ?? this.status,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}
