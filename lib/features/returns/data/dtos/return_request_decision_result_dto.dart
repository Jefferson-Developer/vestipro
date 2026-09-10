import '../../../../core/errors/errors.dart';

/// Shape of `resolveReturnRequest`'s callable response.
final class ReturnRequestDecisionResultDto {
  const ReturnRequestDecisionResultDto({
    required this.returnRequestId,
    required this.orderId,
    required this.status,
    required this.decidedBy,
    required this.decidedAt,
    this.reason,
    this.resultingOrderStatus,
  });

  factory ReturnRequestDecisionResultDto.fromJson(Map<String, dynamic> json) {
    final returnRequestId = json['returnRequestId'];
    final orderId = json['orderId'];
    final status = json['status'];
    final decidedBy = json['decidedBy'];
    final decidedAt = json['decidedAt'];
    final reason = json['reason'];
    final resultingOrderStatus = json['resultingOrderStatus'];
    if (returnRequestId is! String ||
        orderId is! String ||
        status is! String ||
        decidedBy is! String ||
        decidedAt is! String ||
        (reason != null && reason is! String) ||
        (resultingOrderStatus != null && resultingOrderStatus is! String)) {
      throw const ValidationException(
        'Invalid resolveReturnRequest response payload.',
        code: 'invalid_return_request_decision_result_payload',
      );
    }
    return ReturnRequestDecisionResultDto(
      returnRequestId: returnRequestId,
      orderId: orderId,
      status: status,
      decidedBy: decidedBy,
      decidedAt: DateTime.parse(decidedAt),
      reason: reason as String?,
      resultingOrderStatus: resultingOrderStatus as String?,
    );
  }

  final String returnRequestId;
  final String orderId;
  final String status;
  final String decidedBy;
  final DateTime decidedAt;
  final String? reason;
  final String? resultingOrderStatus;
}
