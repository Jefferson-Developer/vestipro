import '../../domain/entities/order_approval_decision.dart';
import '../dtos/order_approval_decision_result_dto.dart';

/// Remote decision of a pedido's approval (EPIC-13, TASK-103) — the
/// contract [OrderApprovalRepositoryImpl] talks to; the only real
/// implementation calls `decideOrderApproval`, never writes an order to
/// Firestore directly (`firestore.rules` denies every client write to
/// `orders` outright — the same rule `OrderSubmissionDataSource` already
/// follows).
abstract interface class OrderApprovalDataSource {
  Future<OrderApprovalDecisionResultDto> decide({
    required String organizationId,
    required String companyId,
    required String orderId,
    required OrderApprovalDecisionValue decision,
    String? reason,
  });
}
