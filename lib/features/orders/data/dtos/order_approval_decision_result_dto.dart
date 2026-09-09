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
    this.approvalChainStatus,
    this.currentLevelIndex,
    this.nextApproverRole,
  });

  factory OrderApprovalDecisionResultDto.fromJson(Map<String, dynamic> json) {
    final orderId = json['orderId'];
    final status = json['status'];
    final approverId = json['approverId'];
    final decidedAt = json['decidedAt'];
    final reason = json['reason'];
    final approvalChainStatus = json['approvalChainStatus'];
    final currentLevelIndex = json['currentLevelIndex'];
    final nextApproverRole = json['nextApproverRole'];

    if (orderId is! String ||
        status is! String ||
        approverId is! String ||
        decidedAt is! String ||
        (reason != null && reason is! String) ||
        (approvalChainStatus != null && approvalChainStatus is! String) ||
        (currentLevelIndex != null && currentLevelIndex is! int) ||
        (nextApproverRole != null && nextApproverRole is! String)) {
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
      approvalChainStatus: approvalChainStatus as String?,
      currentLevelIndex: currentLevelIndex as int?,
      nextApproverRole: nextApproverRole as String?,
    );
  }

  final String orderId;
  final String status;
  final String approverId;
  final DateTime decidedAt;
  final String? reason;
  final String? approvalChainStatus;
  final int? currentLevelIndex;
  final String? nextApproverRole;
}
