import '../../../../core/utils/utils.dart';
import '../entities/order_approval_decision.dart';
import '../entities/order_approval_decision_result.dart';

/// Contract behind deciding a pedido's approval (EPIC-13, TASK-103) — every
/// implementation must call `decideOrderApproval` (the only Cloud Function
/// allowed to move an `Order` out of `underReview` into `approved`/
/// `rejected`, re-validating RBAC and the current status server-side), never
/// a client-side write to Firestore.
abstract interface class OrderApprovalRepository {
  Future<AppResult<OrderApprovalDecisionResult>> decide({
    required String organizationId,
    required String companyId,
    required String orderId,
    required OrderApprovalDecisionValue decision,
    String? reason,
  });
}
