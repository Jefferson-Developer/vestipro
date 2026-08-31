/// How severe one `OrderSubmissionIssue` is (EPIC-13, TASK-100).
///
/// [blocking] issues must keep "Enviar pedido" disabled — the order cannot
/// be submitted while any exist. [warning] issues are surfaced but never
/// disable the CTA by themselves (e.g. a discount that will simply go
/// through approval, `tasks.md`'s own "não bloqueia sozinha" rule for
/// insufficient discount permission).
enum OrderSubmissionIssueSeverity { blocking, warning }

/// Which part of the "novo pedido" screen one `OrderSubmissionIssue` is
/// about — lets the pendencies panel scroll the seller straight to the
/// point of the order that needs adjusting, instead of only naming it in
/// text (TASK-100's "cada item levando diretamente ao ponto do pedido que
/// precisa de ajuste" requirement).
enum OrderSubmissionIssueTarget {
  /// The "Resumo do pedido" card: cliente, tabela de preço ou condição de
  /// pagamento.
  orderSummary,

  /// The items list/grade comercial.
  items,

  /// The commercial summary card (`OrderPricingSummarySection`), where
  /// descontos are shown.
  pricingSummary,
}

/// Every rule `OrderSubmissionValidator` (TASK-100) can report — mirrors,
/// one for one, the checks `tasks.md`/TASK-100 requires: cliente ativo,
/// preço vigente, quantidade disponível/coerente, condição de pagamento
/// válida e permissão do vendedor para o desconto solicitado.
enum OrderSubmissionIssueType {
  itemsEmpty,
  customerNotConfirmed,
  customerInactive,
  customerBlocked,
  priceListNotConfirmed,
  priceListExpired,
  paymentTermNotConfirmed,
  paymentTermInactive,
  paymentTermIncompatibleWithPriceList,
  itemUnavailable,
  itemQuantityExceedsAvailability,
  discountBlocked,
  discountRequiresApproval,
}

/// One pendência (or aviso) `OrderSubmissionValidator` (TASK-100) reports
/// about an `Order` draft, ready to render as-is: [message] is always
/// action-oriented and never exposes a technical detail (`tasks.md`'s "nunca
/// expõem detalhes técnicos" rule for these messages) — there is no separate
/// technical/user-facing pair to keep in sync.
final class OrderSubmissionIssue {
  const OrderSubmissionIssue({
    required this.type,
    required this.severity,
    required this.message,
    required this.target,
    this.productId,
    this.variantId,
  });

  final OrderSubmissionIssueType type;
  final OrderSubmissionIssueSeverity severity;
  final String message;
  final OrderSubmissionIssueTarget target;

  /// Set only for item-level issues ([OrderSubmissionIssueType.itemUnavailable]/
  /// [OrderSubmissionIssueType.itemQuantityExceedsAvailability]) — which
  /// `OrderItem.productId`/`OrderItem.variantId` the issue is about.
  final String? productId;
  final String? variantId;

  bool get isBlocking => severity == OrderSubmissionIssueSeverity.blocking;

  @override
  bool operator ==(Object other) {
    return other is OrderSubmissionIssue &&
        other.type == type &&
        other.severity == severity &&
        other.message == message &&
        other.target == target &&
        other.productId == productId &&
        other.variantId == variantId;
  }

  @override
  int get hashCode =>
      Object.hash(type, severity, message, target, productId, variantId);

  @override
  String toString() =>
      'OrderSubmissionIssue(type: $type, severity: $severity, '
      'message: $message)';
}
