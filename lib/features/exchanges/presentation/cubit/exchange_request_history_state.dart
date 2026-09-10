import '../../domain/entities/exchange_request.dart';

enum ExchangeRequestHistoryStatus { initial, loading, ready, empty, error }

final class ExchangeRequestHistoryState {
  const ExchangeRequestHistoryState({
    this.status = ExchangeRequestHistoryStatus.initial,
    this.exchangeRequests = const <ExchangeRequest>[],
    this.failureMessage,
  });

  final ExchangeRequestHistoryStatus status;
  final List<ExchangeRequest> exchangeRequests;
  final String? failureMessage;

  ExchangeRequestHistoryState copyWith({
    ExchangeRequestHistoryStatus? status,
    List<ExchangeRequest>? exchangeRequests,
    String? failureMessage,
    bool clearFailureMessage = false,
  }) {
    return ExchangeRequestHistoryState(
      status: status ?? this.status,
      exchangeRequests: exchangeRequests ?? this.exchangeRequests,
      failureMessage: clearFailureMessage
          ? null
          : (failureMessage ?? this.failureMessage),
    );
  }
}
