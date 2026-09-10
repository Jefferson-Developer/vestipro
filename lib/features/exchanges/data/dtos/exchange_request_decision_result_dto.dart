import '../../../../core/errors/errors.dart';

/// Shape of `resolveExchangeRequest`'s callable response.
final class ExchangeRequestDecisionResultDto {
  const ExchangeRequestDecisionResultDto({
    required this.exchangeRequestId,
    required this.orderId,
    required this.status,
    required this.decidedBy,
    required this.decidedAt,
    this.reason,
    this.priceDifferenceAmount,
  });

  factory ExchangeRequestDecisionResultDto.fromJson(Map<String, dynamic> json) {
    final exchangeRequestId = json['exchangeRequestId'];
    final orderId = json['orderId'];
    final status = json['status'];
    final decidedBy = json['decidedBy'];
    final decidedAt = json['decidedAt'];
    final reason = json['reason'];
    final priceDifferenceAmount = json['priceDifferenceAmount'];
    if (exchangeRequestId is! String ||
        orderId is! String ||
        status is! String ||
        decidedBy is! String ||
        decidedAt is! String ||
        (reason != null && reason is! String) ||
        (priceDifferenceAmount != null && priceDifferenceAmount is! num)) {
      throw const ValidationException(
        'Invalid resolveExchangeRequest response payload.',
        code: 'invalid_exchange_request_decision_result_payload',
      );
    }
    return ExchangeRequestDecisionResultDto(
      exchangeRequestId: exchangeRequestId,
      orderId: orderId,
      status: status,
      decidedBy: decidedBy,
      decidedAt: DateTime.parse(decidedAt),
      reason: reason as String?,
      priceDifferenceAmount: (priceDifferenceAmount as num?)?.toDouble(),
    );
  }

  final String exchangeRequestId;
  final String orderId;
  final String status;
  final String decidedBy;
  final DateTime decidedAt;
  final String? reason;
  final double? priceDifferenceAmount;
}
