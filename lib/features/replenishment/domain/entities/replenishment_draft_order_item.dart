final class ReplenishmentDraftOrderItem {
  const ReplenishmentDraftOrderItem({
    required this.variantId,
    required this.productId,
    required this.quantity,
  });

  final String variantId;
  final String productId;
  final int quantity;
}
