/// One line of a `BuyerCollaborationSession`'s item snapshot — same shape
/// `CartShareItem`/`CartShareDraftItem` already use for the equivalent
/// single-shot flow (TASK-181), captured fresh every time the seller shares
/// or revises the session.
final class BuyerCollaborationItem {
  const BuyerCollaborationItem({
    required this.itemId,
    required this.productId,
    required this.productName,
    required this.variantId,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  final String itemId;
  final String productId;
  final String productName;
  final String variantId;
  final int quantity;
  final double unitPrice;
  final double subtotal;
}
