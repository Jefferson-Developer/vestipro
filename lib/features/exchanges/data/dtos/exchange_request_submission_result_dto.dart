import '../../../../core/errors/errors.dart';

/// Shape of `createExchangeRequest`'s callable response.
final class ExchangeRequestSubmissionResultDto {
  const ExchangeRequestSubmissionResultDto({
    required this.exchangeRequestId,
    required this.orderId,
    required this.reasonCategory,
    required this.requestedAt,
  });

  factory ExchangeRequestSubmissionResultDto.fromJson(
    Map<String, dynamic> json,
  ) {
    final exchangeRequestId = json['exchangeRequestId'];
    final orderId = json['orderId'];
    final reasonCategory = json['reasonCategory'];
    final requestedAt = json['requestedAt'];
    if (exchangeRequestId is! String ||
        orderId is! String ||
        reasonCategory is! String ||
        requestedAt is! String) {
      throw const ValidationException(
        'Invalid createExchangeRequest response payload.',
        code: 'invalid_exchange_request_submission_result_payload',
      );
    }
    return ExchangeRequestSubmissionResultDto(
      exchangeRequestId: exchangeRequestId,
      orderId: orderId,
      reasonCategory: reasonCategory,
      requestedAt: DateTime.parse(requestedAt),
    );
  }

  final String exchangeRequestId;
  final String orderId;
  final String reasonCategory;
  final DateTime requestedAt;
}
