import '../../domain/entities/return_request.dart';

enum ReturnRequestHistoryStatus { initial, loading, ready, empty, error }

final class ReturnRequestHistoryState {
  const ReturnRequestHistoryState({
    this.status = ReturnRequestHistoryStatus.initial,
    this.returnRequests = const <ReturnRequest>[],
    this.failureMessage,
  });

  final ReturnRequestHistoryStatus status;
  final List<ReturnRequest> returnRequests;
  final String? failureMessage;

  ReturnRequestHistoryState copyWith({
    ReturnRequestHistoryStatus? status,
    List<ReturnRequest>? returnRequests,
    String? failureMessage,
    bool clearFailureMessage = false,
  }) {
    return ReturnRequestHistoryState(
      status: status ?? this.status,
      returnRequests: returnRequests ?? this.returnRequests,
      failureMessage: clearFailureMessage
          ? null
          : (failureMessage ?? this.failureMessage),
    );
  }
}
