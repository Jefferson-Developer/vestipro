import '../value_objects/order_status.dart';
import 'order_approval_decision.dart';

/// Result of successfully deciding a pedido's approval through
/// `decideOrderApproval` (TASK-103) — every field here is exactly what the
/// Cloud Function returned, never recomputed client-side (same "pricing/
/// aprovação definitiva server-side" precedent [OrderSubmissionResult]
/// already follows).
final class OrderApprovalDecisionResult {
  const OrderApprovalDecisionResult({
    required this.orderId,
    required this.status,
    required this.approverId,
    required this.decidedAt,
    this.reason,
  });

  final String orderId;

  /// Always [OrderStatus.approved] or [OrderStatus.rejected] — never any
  /// other [OrderStatus] value, mirrored from
  /// [OrderApprovalDecisionValue]'s own closed set.
  final OrderStatus status;
  final String approverId;
  final DateTime decidedAt;
  final String? reason;
}
