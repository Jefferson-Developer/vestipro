import '../../../../core/utils/utils.dart';
import '../entities/return_request.dart';
import '../entities/return_request_decision_result.dart';
import '../entities/return_request_item.dart';
import '../entities/return_request_submission_result.dart';
import '../value_objects/return_reason_category.dart';
import '../value_objects/return_request_status.dart';

abstract interface class ReturnRequestRepository {
  /// Calls `createReturnRequest` (Cloud Function) — never a direct
  /// Firestore write (`AGENTS.md`: regras de negócio críticas ficam no
  /// backend). [returnRequestId] is the client-generated idempotency
  /// key/document id: a retried call with the same id always replays the
  /// same result instead of opening a second devolução.
  Future<AppResult<ReturnRequestSubmissionResult>> createReturnRequest({
    required String organizationId,
    required String companyId,
    required String orderId,
    required String returnRequestId,
    required List<ReturnRequestItemInput> items,
    required ReturnReasonCategory reasonCategory,
    String? reasonDetails,
    List<String> evidenceUrls,
  });

  /// Calls `resolveReturnRequest` (Cloud Function) — the only place a
  /// devolução's stock/financial effect is ever applied.
  Future<AppResult<ReturnRequestDecisionResult>> resolveReturnRequest({
    required String organizationId,
    required String companyId,
    required String returnRequestId,
    required ReturnRequestDecisionValue decision,
    String? reason,
  });

  /// Every `ReturnRequest` linked to [orderId] — feeds the pedido's own
  /// history/detail screen (TASK-102/TASK-199).
  Stream<AppResult<List<ReturnRequest>>> watchByOrder({
    required String organizationId,
    required String orderId,
  });

  /// Every `ReturnRequest` still [ReturnRequestStatus.requested] visible to
  /// the caller — feeds the analysis queue (TASK-199). [sellerIds] narrows
  /// the query to a manager's own team when [allCompany] is `false`; an
  /// empty [sellerIds] with [allCompany] `false` means nothing is visible
  /// (`OrderVisibilityMode.none`'s own precedent).
  Stream<AppResult<List<ReturnRequest>>> watchQueue({
    required String organizationId,
    required String companyId,
    required bool allCompany,
    Set<String> sellerIds,
  });
}
