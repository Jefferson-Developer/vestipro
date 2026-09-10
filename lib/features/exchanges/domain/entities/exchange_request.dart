import '../value_objects/exchange_reason_category.dart';
import '../value_objects/exchange_request_status.dart';
import 'exchange_request_decision.dart';
import 'exchange_request_item.dart';

/// A troca (exchange of variant — cor/tamanho) request against an
/// already-fulfilled `Order` (TASK-200, EPIC-30) — always vinculada a um
/// pedido original ([orderId]), com motivo obrigatório categorizado
/// ([reasonCategory]) e histórico completo de decisões ([decisions]).
/// Reaproveita o mesmo ciclo de aprovação/RBAC/auditoria de `ReturnRequest`
/// (TASK-199), mas nunca altera o `status` do pedido em si: o cliente
/// continua com a mesma quantidade total de mercadoria, apenas uma variante
/// diferente — logo, nenhuma reversão de comissão se aplica aqui.
///
/// Exclusively written by `createExchangeRequest`/`resolveExchangeRequest`
/// (Cloud Functions) — the UI never mutates one directly; this entity is
/// only ever read back through [ExchangeRequestRepository.watchByOrder]/
/// `watchQueue`.
final class ExchangeRequest {
  const ExchangeRequest({
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
    required this.status,
    this.priceDifferenceAmount,
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
  final List<ExchangeRequestItem> items;
  final ExchangeReasonCategory reasonCategory;
  final String? reasonDetails;
  final ExchangeRequestStatus status;

  /// Positive: cliente deve a diferença; negative: cliente recebe a
  /// diferença de volta; `0`: variantes de mesmo preço vigente. `null`
  /// until [status] is [ExchangeRequestStatus.approved] — a recusa never
  /// prices anything, and this value is always computed at approval time by
  /// the pricing engine's *current* price, never the estimate carried since
  /// the solicitação.
  final double? priceDifferenceAmount;
  final String requestedBy;
  final String? requestedByName;
  final DateTime requestedAt;
  final List<ExchangeRequestDecision> decisions;
  final String? decidedBy;
  final DateTime? decidedAt;
  final String? decisionReason;

  int get totalRequestedQuantity =>
      items.fold(0, (sum, item) => sum + item.quantity);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExchangeRequest &&
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
          other.status == status &&
          other.priceDifferenceAmount == priceDifferenceAmount &&
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
    status,
    priceDifferenceAmount,
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
