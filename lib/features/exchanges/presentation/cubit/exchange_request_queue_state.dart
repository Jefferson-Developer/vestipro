import '../../domain/entities/exchange_request.dart';

enum ExchangeRequestQueueStatus { initial, loading, ready, empty, error }

enum ExchangeRequestDecisionStatus { idle, deciding, success, failure }

final class ExchangeRequestQueueState {
  const ExchangeRequestQueueState({
    this.status = ExchangeRequestQueueStatus.initial,
    this.exchangeRequests = const <ExchangeRequest>[],
    this.failureMessage,
    this.decisionStatus = ExchangeRequestDecisionStatus.idle,
    this.decidingExchangeRequestId,
    this.decisionFailureMessage,
  });

  final ExchangeRequestQueueStatus status;
  final List<ExchangeRequest> exchangeRequests;
  final String? failureMessage;
  final ExchangeRequestDecisionStatus decisionStatus;
  final String? decidingExchangeRequestId;
  final String? decisionFailureMessage;

  ExchangeRequestQueueState copyWith({
    ExchangeRequestQueueStatus? status,
    List<ExchangeRequest>? exchangeRequests,
    String? failureMessage,
    bool clearFailureMessage = false,
    ExchangeRequestDecisionStatus? decisionStatus,
    String? decidingExchangeRequestId,
    bool clearDecidingExchangeRequestId = false,
    String? decisionFailureMessage,
    bool clearDecisionFailureMessage = false,
  }) {
    return ExchangeRequestQueueState(
      status: status ?? this.status,
      exchangeRequests: exchangeRequests ?? this.exchangeRequests,
      failureMessage: clearFailureMessage
          ? null
          : (failureMessage ?? this.failureMessage),
      decisionStatus: decisionStatus ?? this.decisionStatus,
      decidingExchangeRequestId: clearDecidingExchangeRequestId
          ? null
          : (decidingExchangeRequestId ?? this.decidingExchangeRequestId),
      decisionFailureMessage: clearDecisionFailureMessage
          ? null
          : (decisionFailureMessage ?? this.decisionFailureMessage),
    );
  }
}
