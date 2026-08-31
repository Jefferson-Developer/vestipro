import '../../../../core/errors/errors.dart';

/// Plain-JSON shape of `decideOrderApproval`'s callable response
/// (`functions/src/orders/decide-order-approval.ts`'s
/// `DecideOrderApprovalResponse`, TASK-103) — `correlationId` is not parsed
/// here, same precedent [OrderSubmissionResultDto] already sets for its own
/// callable response.
final class OrderApprovalDecisionResultDto {
  const OrderApprovalDecisionResultDto({
    required this.orderId,
    required this.status,
    required this.approverId,
    required this.decidedAt,
    this.reason,
  });

  factory OrderApprovalDecisionResultDto.fromJson(Map<String, dynamic> json) {
    final orderId = json['orderId'];
    final status = json['status'];
    final approverId = json['approverId'];
    final decidedAt = json['decidedAt'];
    final reason = json['reason'];

    if (orderId is! String ||
        status is! String ||
        approverId is! String ||
        decidedAt is! String ||
        (reason != null && reason is! String)) {
      throw const ServerException(
        'Unexpected decideOrderApproval callable response shape.',
        code: 'invalid_order_approval_decision_response',
      );
    }

    final parsedDecidedAt = DateTime.tryParse(decidedAt);
    if (parsedDecidedAt == null) {
      throw const ServerException(
        'Unexpected decideOrderApproval decidedAt format.',
        code: 'invalid_order_approval_decision_response',
      );
    }

    return OrderApprovalDecisionResultDto(
      orderId: orderId,
      status: status,
      approverId: approverId,
      decidedAt: parsedDecidedAt,
      reason: reason as String?,
    );
  }

  final String orderId;
  final String status;
  final String approverId;
  final DateTime decidedAt;
  final String? reason;
}
