import '../../../../core/errors/errors.dart';
import '../../domain/entities/order.dart';

enum OrderApprovalQueueLoadStatus {
  initial,
  loading,
  ready,
  loadingMore,
  failure,
}

const int kOrderApprovalQueuePageSize = 20;

/// Drives the fila de aprovação screen (TASK-103): every pedido this caller
/// may decide, currently `underReview` — visibility-scoped the exact same
/// way the pedidos listing screen already is (`OrderVisibilityService`, via
/// `ListOrdersUseCase`), so a `SALES_MANAGER` only ever sees their own
/// teams' pedidos here too, never the whole organization's.
final class OrderApprovalQueueState {
  const OrderApprovalQueueState({
    this.loadStatus = OrderApprovalQueueLoadStatus.initial,
    this.organizationId = '',
    this.companyId = '',
    this.userId = '',
    this.orders = const <Order>[],
    this.hasMore = false,
    this.isLoadingMore = false,
    this.nextCursor,
    this.failure,
    this.decidingOrderId,
    this.decisionFailure,
  });

  final OrderApprovalQueueLoadStatus loadStatus;
  final String organizationId;
  final String companyId;
  final String userId;
  final List<Order> orders;
  final bool hasMore;
  final bool isLoadingMore;
  final DateTime? nextCursor;
  final Failure? failure;

  /// The id of the pedido currently being decided (approve/reject in
  /// flight) — drives a per-row loading indicator so the approver cannot
  /// double-submit a decision by tapping twice.
  final String? decidingOrderId;

  /// Set only when the most recent decision attempt failed — never blocks
  /// the queue itself (the pedido stays visible so the approver can retry).
  final Failure? decisionFailure;

  bool get isInitialLoading =>
      loadStatus == OrderApprovalQueueLoadStatus.initial ||
      loadStatus == OrderApprovalQueueLoadStatus.loading;

  OrderApprovalQueueState copyWith({
    OrderApprovalQueueLoadStatus? loadStatus,
    String? organizationId,
    String? companyId,
    String? userId,
    List<Order>? orders,
    bool? hasMore,
    bool? isLoadingMore,
    DateTime? nextCursor,
    bool clearNextCursor = false,
    Failure? failure,
    bool clearFailure = false,
    String? decidingOrderId,
    bool clearDecidingOrderId = false,
    Failure? decisionFailure,
    bool clearDecisionFailure = false,
  }) {
    return OrderApprovalQueueState(
      loadStatus: loadStatus ?? this.loadStatus,
      organizationId: organizationId ?? this.organizationId,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      orders: orders ?? this.orders,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      nextCursor: clearNextCursor ? null : nextCursor ?? this.nextCursor,
      failure: clearFailure ? null : failure ?? this.failure,
      decidingOrderId: clearDecidingOrderId
          ? null
          : decidingOrderId ?? this.decidingOrderId,
      decisionFailure: clearDecisionFailure
          ? null
          : decisionFailure ?? this.decisionFailure,
    );
  }
}
