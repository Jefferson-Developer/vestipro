import '../value_objects/return_reason_category.dart';
import '../value_objects/return_request_status.dart';
import 'return_request_decision.dart';
import 'return_request_item.dart';

/// A devolução (RMA) request against an already-fulfilled `Order` (TASK-199,
/// EPIC-30) — always vinculada a um pedido original ([orderId]), com motivo
/// obrigatório categorizado ([reasonCategory]) e histórico completo de
/// decisões ([decisions]).
///
/// Exclusively written by `createReturnRequest`/`resolveReturnRequest`
/// (Cloud Functions) — the UI never mutates one directly (no
/// Firestore/Storage write from a widget, `AGENTS.md`); this entity is only
/// ever read back through [ReturnRequestRepository.watchByOrder]/
/// `watchQueue`.
final class ReturnRequest {
  const ReturnRequest({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.orderId,
    this.orderNumber,
    required this.customerId,
    required this.sellerId,
    required this.currency,
    required this.items,
    required this.reasonCategory,
    this.reasonDetails,
    required this.evidenceUrls,
    required this.status,
    required this.refundAmount,
    required this.requestedBy,
    this.requestedByName,
    required this.requestedAt,
    required this.decisions,
    this.decidedBy,
    this.decidedAt,
    this.decisionReason,
  });

  final String id;
  final String organizationId;
  final String companyId;
  final String orderId;
  final String? orderNumber;
  final String customerId;
  final String sellerId;
  final String currency;
  final List<ReturnRequestItem> items;
  final ReturnReasonCategory reasonCategory;
  final String? reasonDetails;
  final List<String> evidenceUrls;
  final ReturnRequestStatus status;

  /// Sum of every [ReturnRequestItem.subtotal] — the devolução's own
  /// traceable financial impact (`tasks.md`: "sinalizar o impacto
  /// financeiro... de forma rastreável até o pedido original"). Emitting a
  /// formal nota de crédito/lançamento em contas a receber is TASK-213's own
  /// scope, not yet implemented — see this task's "Pendências".
  final double refundAmount;
  final String requestedBy;
  final String? requestedByName;
  final DateTime requestedAt;
  final List<ReturnRequestDecision> decisions;
  final String? decidedBy;
  final DateTime? decidedAt;
  final String? decisionReason;

  int get totalRequestedQuantity =>
      items.fold(0, (sum, item) => sum + item.quantity);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReturnRequest &&
          other.id == id &&
          other.organizationId == organizationId &&
          other.companyId == companyId &&
          other.orderId == orderId &&
          other.orderNumber == orderNumber &&
          other.customerId == customerId &&
          other.sellerId == sellerId &&
          other.currency == currency &&
          _listEquals(other.items, items) &&
          other.reasonCategory == reasonCategory &&
          other.reasonDetails == reasonDetails &&
          _listEquals(other.evidenceUrls, evidenceUrls) &&
          other.status == status &&
          other.refundAmount == refundAmount &&
          other.requestedBy == requestedBy &&
          other.requestedByName == requestedByName &&
          other.requestedAt == requestedAt &&
          _listEquals(other.decisions, decisions) &&
          other.decidedBy == decidedBy &&
          other.decidedAt == decidedAt &&
          other.decisionReason == decisionReason);

  @override
  int get hashCode => Object.hash(
    Object.hash(
      id,
      organizationId,
      companyId,
      orderId,
      orderNumber,
      customerId,
      sellerId,
      currency,
      Object.hashAll(items),
      reasonCategory,
    ),
    reasonDetails,
    Object.hashAll(evidenceUrls),
    status,
    refundAmount,
    requestedBy,
    requestedByName,
    requestedAt,
    Object.hashAll(decisions),
    decidedBy,
    decidedAt,
    decisionReason,
  );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
