/// One item `DuplicateOrderUseCase` (TASK-104) carried over into the new
/// draft whose current price (`ResolvePriceForVariantUseCase`, TASK-088)
/// differs from [previousUnitPrice] — the exact price captured on the source
/// order's own `OrderItem.unitPrice`. The new draft's item already uses
/// [newUnitPrice] by the time this is reported: this is purely informative,
/// so the seller is never surprised by a total that silently changed from
/// the order they meant to repeat (`tasks.md`'s own "sinalizar claramente...
/// teve o preço alterado" rule).
final class OrderDuplicationPriceChange {
  const OrderDuplicationPriceChange({
    required this.productId,
    required this.variantId,
    required this.previousUnitPrice,
    required this.newUnitPrice,
  });

  final String productId;
  final String variantId;
  final double previousUnitPrice;
  final double newUnitPrice;

  bool get increased => newUnitPrice > previousUnitPrice;

  @override
  bool operator ==(Object other) {
    return other is OrderDuplicationPriceChange &&
        other.productId == productId &&
        other.variantId == variantId &&
        other.previousUnitPrice == previousUnitPrice &&
        other.newUnitPrice == newUnitPrice;
  }

  @override
  int get hashCode =>
      Object.hash(productId, variantId, previousUnitPrice, newUnitPrice);

  @override
  String toString() =>
      'OrderDuplicationPriceChange(productId: $productId, '
      'variantId: $variantId, previousUnitPrice: $previousUnitPrice, '
      'newUnitPrice: $newUnitPrice)';
}
