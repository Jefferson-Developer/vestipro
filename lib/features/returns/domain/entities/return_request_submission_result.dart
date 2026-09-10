import '../value_objects/return_reason_category.dart';

/// The immediate outcome of [CreateReturnRequestUseCase] — deliberately
/// lighter than the full [ReturnRequest] entity (mirrors
/// `OrderSubmissionResultDto` vs. `Order`, TASK-101): the UI's own
/// `ReturnRequestHistoryCubit`/`ReturnRequestQueueCubit` (already watching
/// `organizations/{organizationId}/returnRequests`) picks up the newly
/// created document through that stream, so this result only needs to carry
/// enough to drive an immediate "solicitação enviada" confirmation.
final class ReturnRequestSubmissionResult {
  const ReturnRequestSubmissionResult({
    required this.returnRequestId,
    required this.orderId,
    required this.reasonCategory,
    required this.refundAmount,
    required this.requestedAt,
  });

  final String returnRequestId;
  final String orderId;
  final ReturnReasonCategory reasonCategory;
  final double refundAmount;
  final DateTime requestedAt;
}
