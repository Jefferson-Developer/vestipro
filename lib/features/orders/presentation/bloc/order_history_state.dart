import '../../../../core/errors/errors.dart';
import '../../domain/entities/order.dart';

enum OrderHistoryLoadStatus { initial, loading, ready, failure }

/// Drives the pedido history/detail screen (TASK-104): a single Order
/// (`GetOrderByIdUseCase`, RBAC-scoped the same way the pedidos listing
/// screen already is) rendered as a read-only status timeline.
final class OrderHistoryState {
  const OrderHistoryState({
    this.loadStatus = OrderHistoryLoadStatus.initial,
    this.organizationId = '',
    this.companyId = '',
    this.userId = '',
    this.orderId = '',
    this.order,
    this.failure,
  });

  final OrderHistoryLoadStatus loadStatus;
  final String organizationId;
  final String companyId;
  final String userId;
  final String orderId;
  final Order? order;
  final Failure? failure;

  bool get isLoading =>
      loadStatus == OrderHistoryLoadStatus.initial ||
      loadStatus == OrderHistoryLoadStatus.loading;

  OrderHistoryState copyWith({
    OrderHistoryLoadStatus? loadStatus,
    String? organizationId,
    String? companyId,
    String? userId,
    String? orderId,
    Order? order,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return OrderHistoryState(
      loadStatus: loadStatus ?? this.loadStatus,
      organizationId: organizationId ?? this.organizationId,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      orderId: orderId ?? this.orderId,
      order: order ?? this.order,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }
}
