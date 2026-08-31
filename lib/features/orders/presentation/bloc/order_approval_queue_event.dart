import '../../domain/entities/order_approval_decision.dart';

sealed class OrderApprovalQueueEvent {
  const OrderApprovalQueueEvent();
}

final class OrderApprovalQueueStarted extends OrderApprovalQueueEvent {
  const OrderApprovalQueueStarted({
    required this.organizationId,
    required this.companyId,
    required this.userId,
  });

  final String organizationId;
  final String companyId;
  final String userId;
}

final class OrderApprovalQueueRefreshRequested extends OrderApprovalQueueEvent {
  const OrderApprovalQueueRefreshRequested();
}

final class OrderApprovalQueueNextPageRequested
    extends OrderApprovalQueueEvent {
  const OrderApprovalQueueNextPageRequested();
}

/// Approves/rejects [orderId] — [reason] is mandatory for
/// [OrderApprovalDecisionValue.rejected] (enforced by
/// `DecideOrderApprovalUseCase`, never only by the dialog that collected it).
final class OrderApprovalQueueDecided extends OrderApprovalQueueEvent {
  const OrderApprovalQueueDecided({
    required this.orderId,
    required this.decision,
    this.reason,
  });

  final String orderId;
  final OrderApprovalDecisionValue decision;
  final String? reason;
}
