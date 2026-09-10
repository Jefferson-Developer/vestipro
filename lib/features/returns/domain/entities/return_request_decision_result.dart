import '../value_objects/return_request_status.dart';

/// The immediate outcome of [ResolveReturnRequestUseCase] — same
/// deliberately-lighter shape as [ReturnRequestSubmissionResult] vs.
/// [ReturnRequest] (mirrors `DecideOrderApprovalResponse` vs. `Order`,
/// TASK-103): the queue/history screens rely on their own watch stream to
/// reflect the now-decided devolução, this result only drives the immediate
/// confirmation feedback.
final class ReturnRequestDecisionResult {
  const ReturnRequestDecisionResult({
    required this.returnRequestId,
    required this.orderId,
    required this.status,
    required this.decidedBy,
    required this.decidedAt,
    this.reason,
    this.resultingOrderStatusLabel,
  });

  final String returnRequestId;
  final String orderId;
  final ReturnRequestStatus status;
  final String decidedBy;
  final DateTime decidedAt;
  final String? reason;

  /// `'returned'`/`'partiallyReturned'` when [status] is
  /// [ReturnRequestStatus.approved] — the pedido's own new status after
  /// stock reintegration, `null` for a recusa (never applied).
  final String? resultingOrderStatusLabel;
}
