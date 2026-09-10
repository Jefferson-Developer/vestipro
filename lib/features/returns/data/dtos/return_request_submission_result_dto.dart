import '../../../../core/errors/errors.dart';

/// Shape of `createReturnRequest`'s callable response.
final class ReturnRequestSubmissionResultDto {
  const ReturnRequestSubmissionResultDto({
    required this.returnRequestId,
    required this.orderId,
    required this.reasonCategory,
    required this.refundAmount,
    required this.requestedAt,
  });

  factory ReturnRequestSubmissionResultDto.fromJson(Map<String, dynamic> json) {
    final returnRequestId = json['returnRequestId'];
    final orderId = json['orderId'];
    final reasonCategory = json['reasonCategory'];
    final refundAmount = json['refundAmount'];
    final requestedAt = json['requestedAt'];
    if (returnRequestId is! String ||
        orderId is! String ||
        reasonCategory is! String ||
        refundAmount is! num ||
        requestedAt is! String) {
      throw const ValidationException(
        'Invalid createReturnRequest response payload.',
        code: 'invalid_return_request_submission_result_payload',
      );
    }
    return ReturnRequestSubmissionResultDto(
      returnRequestId: returnRequestId,
      orderId: orderId,
      reasonCategory: reasonCategory,
      refundAmount: refundAmount.toDouble(),
      requestedAt: DateTime.parse(requestedAt),
    );
  }

  final String returnRequestId;
  final String orderId;
  final String reasonCategory;
  final double refundAmount;
  final DateTime requestedAt;
}
