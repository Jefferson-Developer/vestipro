/// Why one item of the source order could not be silently copied into the
/// new draft `DuplicateOrderUseCase` (TASK-104) creates — `tasks.md`'s own
/// "item descontinuado ou sem variante equivalente não pode ser copiado
/// silenciosamente" rule. Every value here excludes the item from the new
/// draft entirely: the seller must go back to the catalog and pick a
/// replacement, never have a stale/invalid line added on their behalf.
enum OrderDuplicationItemIssueType {
  /// The variant no longer exists, or exists but is no longer
  /// [ProductVariantStatus.active] (`ProductVariantRepository.getById`).
  discontinued,

  /// The variant still exists and is active, but
  /// `GetVariantAvailabilityUseCase` reports it as not currently sellable
  /// (`VariantAvailability.acceptsQuantity` is `false`).
  unavailable,

  /// `ResolvePriceForVariantUseCase` (TASK-088) found no applicable price
  /// for this variant right now — copying the old, possibly stale
  /// [OrderItem.unitPrice] would violate the "nunca copiar preço antigo"
  /// rule, so the item is excluded instead.
  priceUnavailable,
}

/// One item of the source order `DuplicateOrderUseCase` (TASK-104) excluded
/// from the new draft, ready to render as-is: [requestedQuantity] is the
/// quantity the item had on the source order (never copied onto the new
/// draft), kept only so the seller can see what they are missing and decide
/// whether to look for a replacement.
final class OrderDuplicationItemIssue {
  const OrderDuplicationItemIssue({
    required this.productId,
    required this.variantId,
    required this.type,
    required this.requestedQuantity,
  });

  final String productId;
  final String variantId;
  final OrderDuplicationItemIssueType type;
  final int requestedQuantity;

  @override
  bool operator ==(Object other) {
    return other is OrderDuplicationItemIssue &&
        other.productId == productId &&
        other.variantId == variantId &&
        other.type == type &&
        other.requestedQuantity == requestedQuantity;
  }

  @override
  int get hashCode =>
      Object.hash(productId, variantId, type, requestedQuantity);

  @override
  String toString() =>
      'OrderDuplicationItemIssue(productId: $productId, '
      'variantId: $variantId, type: $type)';
}
