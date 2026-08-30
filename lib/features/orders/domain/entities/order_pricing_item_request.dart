/// One `OrderItem` translated into what `calculatePricing`
/// (`functions/src/pricing/calculate-pricing.ts`, TASK-088) needs to price it
/// — never the item itself, so [OrderPricingRepository] implementations never
/// depend on the orders feature's own item shape changing.
final class OrderPricingItemRequest {
  const OrderPricingItemRequest({
    required this.productId,
    required this.quantity,
    this.variantId,
    this.collectionId,
    this.categoryId,
    this.manualDiscountPercent = 0,
  });

  final String productId;
  final String? variantId;
  final int quantity;

  /// The order's own `collectionId` (`Order.collectionId`), when the seller
  /// narrowed the catalog to one collection — every item on the same order
  /// shares it, there is no per-item collection today.
  final String? collectionId;

  /// Deliberately always `null` for now: `OrderItem` has no per-item category
  /// reference, and resolving one would require fetching each item's
  /// `Product` just for this field — out of TASK-099's scope. Category-scoped
  /// campaigns simply do not match on these items yet; product/collection-
  /// scoped campaigns are unaffected.
  final String? categoryId;

  /// Deliberately always `0` for now: TASK-099's order draft screen has no
  /// per-item manual discount entry yet (no earlier EPIC-13 task added one),
  /// so there is nothing captured on `OrderItem` to translate into a percent
  /// — never guessed from `OrderItem.discountAmount`, which is not the same
  /// unit. A future task wiring manual discount entry into the draft must
  /// populate this for real.
  final double manualDiscountPercent;
}
