import '../../../../core/utils/utils.dart';
import '../entities/exchange_request.dart';
import '../entities/exchange_request_decision_result.dart';
import '../entities/exchange_request_item.dart';
import '../entities/exchange_request_submission_result.dart';
import '../value_objects/exchange_reason_category.dart';
import '../value_objects/exchange_request_status.dart';

abstract interface class ExchangeRequestRepository {
  /// Calls `createExchangeRequest` (Cloud Function) — never a direct
  /// Firestore write (`AGENTS.md`: regras de negócio críticas ficam no
  /// backend). [exchangeRequestId] is the client-generated idempotency
  /// key/document id: a retried call with the same id always replays the
  /// same result instead of opening a second troca.
  Future<AppResult<ExchangeRequestSubmissionResult>> createExchangeRequest({
    required String organizationId,
    required String companyId,
    required String orderId,
    required String exchangeRequestId,
    required List<ExchangeRequestItemInput> items,
    required ExchangeReasonCategory reasonCategory,
    String? reasonDetails,
  });

  /// Calls `resolveExchangeRequest` (Cloud Function) — the only place a
  /// troca's stock/pricing effect is ever applied.
  Future<AppResult<ExchangeRequestDecisionResult>> resolveExchangeRequest({
    required String organizationId,
    required String companyId,
    required String exchangeRequestId,
    required ExchangeRequestDecisionValue decision,
    String? reason,
  });

  /// Every `ExchangeRequest` linked to [orderId] — feeds the pedido's own
  /// history/detail screen (TASK-102/TASK-200).
  Stream<AppResult<List<ExchangeRequest>>> watchByOrder({
    required String organizationId,
    required String orderId,
  });

  /// Every `ExchangeRequest` still [ExchangeRequestStatus.requested] visible
  /// to the caller — feeds the analysis queue (TASK-200). [sellerIds]
  /// narrows the query to a manager's own team when [allCompany] is `false`;
  /// an empty [sellerIds] with [allCompany] `false` means nothing is visible
  /// (`OrderVisibilityMode.none`'s own precedent).
  Stream<AppResult<List<ExchangeRequest>>> watchQueue({
    required String organizationId,
    required String companyId,
    required bool allCompany,
    Set<String> sellerIds,
  });
}
