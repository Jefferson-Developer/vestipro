import '../value_objects/exchange_request_status.dart';

/// The immediate outcome of [ResolveExchangeRequestUseCase] — same
/// deliberately-lighter shape as [ExchangeRequestSubmissionResult] vs.
/// [ExchangeRequest] (mirrors `ReturnRequestDecisionResult`, TASK-199): the
/// queue/history screens rely on their own watch stream to reflect the
/// now-decided troca, this result only drives the immediate confirmation
/// feedback.
final class ExchangeRequestDecisionResult {
  const ExchangeRequestDecisionResult({
    required this.exchangeRequestId,
    required this.orderId,
    required this.status,
    required this.decidedBy,
    required this.decidedAt,
    this.reason,
    this.priceDifferenceAmount,
  });

  final String exchangeRequestId;
  final String orderId;
  final ExchangeRequestStatus status;
  final String decidedBy;
  final DateTime decidedAt;
  final String? reason;

  /// `null` for a recusa (never priced); computed by the pricing engine's
  /// current price for the destination variant when [status] is
  /// [ExchangeRequestStatus.approved].
  final double? priceDifferenceAmount;
}
