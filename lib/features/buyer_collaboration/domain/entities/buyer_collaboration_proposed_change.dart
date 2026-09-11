import '../value_objects/buyer_collaboration_comment_kind.dart';

/// One structured suggestion inside a buyer's `changesRequested` comment —
/// a quantity update, a removal, or a brand-new item to add. Rendered by the
/// seller's UI as an actionable list; applying any of them still always goes
/// through `ShareBuyerCollaborationSessionUseCase` (the seller revises and
/// re-shares), never automatically (`tasks.md`: "a conversão em pedido
/// continua passando pelo vendedor").
final class BuyerCollaborationProposedChange {
  const BuyerCollaborationProposedChange({
    required this.itemId,
    required this.action,
    this.requestedQuantity,
    this.productId,
    this.variantId,
    this.productName,
  });

  final String itemId;
  final BuyerCollaborationProposedChangeAction action;
  final int? requestedQuantity;
  final String? productId;
  final String? variantId;
  final String? productName;
}
