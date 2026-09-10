import '../../domain/entities/return_request.dart';

enum ReturnRequestQueueStatus { initial, loading, ready, empty, error }

enum ReturnRequestDecisionStatus { idle, deciding, success, failure }

final class ReturnRequestQueueState {
  const ReturnRequestQueueState({
    this.status = ReturnRequestQueueStatus.initial,
    this.returnRequests = const <ReturnRequest>[],
    this.failureMessage,
    this.decisionStatus = ReturnRequestDecisionStatus.idle,
    this.decidingReturnRequestId,
    this.decisionFailureMessage,
  });

  final ReturnRequestQueueStatus status;
  final List<ReturnRequest> returnRequests;
  final String? failureMessage;
  final ReturnRequestDecisionStatus decisionStatus;
  final String? decidingReturnRequestId;
  final String? decisionFailureMessage;

  ReturnRequestQueueState copyWith({
    ReturnRequestQueueStatus? status,
    List<ReturnRequest>? returnRequests,
    String? failureMessage,
    bool clearFailureMessage = false,
    ReturnRequestDecisionStatus? decisionStatus,
    String? decidingReturnRequestId,
    bool clearDecidingReturnRequestId = false,
    String? decisionFailureMessage,
    bool clearDecisionFailureMessage = false,
  }) {
    return ReturnRequestQueueState(
      status: status ?? this.status,
      returnRequests: returnRequests ?? this.returnRequests,
      failureMessage: clearFailureMessage
          ? null
          : (failureMessage ?? this.failureMessage),
      decisionStatus: decisionStatus ?? this.decisionStatus,
      decidingReturnRequestId: clearDecidingReturnRequestId
          ? null
          : (decidingReturnRequestId ?? this.decidingReturnRequestId),
      decisionFailureMessage: clearDecisionFailureMessage
          ? null
          : (decisionFailureMessage ?? this.decisionFailureMessage),
    );
  }
}
