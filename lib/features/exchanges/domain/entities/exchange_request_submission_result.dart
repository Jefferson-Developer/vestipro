import '../value_objects/exchange_reason_category.dart';

/// The immediate outcome of [CreateExchangeRequestUseCase] — deliberately
/// lighter than the full [ExchangeRequest] entity (mirrors
/// `ReturnRequestSubmissionResult` vs. `ReturnRequest`, TASK-199): the UI's
/// own `ExchangeRequestHistoryCubit`/`ExchangeRequestQueueCubit` (already
/// watching `organizations/{organizationId}/exchangeRequests`) picks up the
/// newly created document through that stream, so this result only needs to
/// carry enough to drive an immediate "solicitação enviada" confirmation.
final class ExchangeRequestSubmissionResult {
  const ExchangeRequestSubmissionResult({
    required this.exchangeRequestId,
    required this.orderId,
    required this.reasonCategory,
    required this.requestedAt,
  });

  final String exchangeRequestId;
  final String orderId;
  final ExchangeReasonCategory reasonCategory;
  final DateTime requestedAt;
}
