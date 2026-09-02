/// Per-draft-order dataset used by [AbandonedDraftOrderInsightRule] (TASK-130)
/// to detect order drafts (`OrderStatus.draft`/`pendingSync`, TASK-096) left
/// untouched for too long, distinguishing a recently-parked "carrinho salvo"
/// from a truly stale "pedido abandonado".
final class InsightAbandonedOrderSnapshot {
  const InsightAbandonedOrderSnapshot({
    required this.orderId,
    required this.organizationId,
    required this.companyId,
    required this.recipientUserId,
    required this.customerId,
    required this.customerName,
    required this.lastContentChangeAt,
    required this.itemCount,
    required this.estimatedValue,
    this.hasPendingOutboxSync = false,
    this.startedInServiceContext = false,
    this.hasInvalidReference = false,
    this.invalidReferenceReason,
  });

  final String orderId;
  final String organizationId;
  final String companyId;
  final String recipientUserId;
  final String customerId;
  final String customerName;

  /// Timestamp of the last time the draft's *content* (items/quantities) was
  /// changed by the seller — never the last Outbox sync attempt. This is the
  /// only signal the rule uses to detect staleness: a draft with a pending
  /// Outbox sync (TASK-108) but recently edited content must never be
  /// confused with an abandoned draft.
  final DateTime lastContentChangeAt;

  final int itemCount;

  /// Sum of the items already included in the draft — the potential revenue
  /// at risk if the draft is never submitted.
  final double estimatedValue;

  /// Purely informational: whether this draft still has a pending Outbox
  /// mutation (TASK-108). Intentionally never read by the rule's staleness
  /// gate — only [lastContentChangeAt] decides abandonment, per this task's
  /// own acceptance criteria.
  final bool hasPendingOutboxSync;

  /// Whether the draft was started while the seller was actively assisting
  /// this customer (e.g. a call/visit), which makes "Contatar cliente" a
  /// relevant secondary action alongside "Retomar pedido".
  final bool startedInServiceContext;

  /// Whether the draft references a customer/product that has since been
  /// deleted, or a price list that has since expired. When `true`, resuming
  /// the draft must surface an explicit warning — never reopen silently.
  final bool hasInvalidReference;

  /// Human-readable reason for [hasInvalidReference] (e.g. "Cliente
  /// excluído", "Tabela de preço expirada"), shown in the insight evidence
  /// and used to build the resume warning.
  final String? invalidReferenceReason;
}
