/// One concrete, sellable `ProductVariant` a `CommercialPack`'s composition
/// resolved to, with the exact quantity one instance of the pack requires of
/// it (TASK-208, EPIC-32) — the output of `CommercialPackComposer.compose`.
///
/// Deliberately carries no price: turning [variantId]/[quantity] into a
/// priced `OrderItem` (client-side estimate) or into a server-priced line
/// (`calculatePricing`) is always the caller's job, never this entity's —
/// same "contract only" precedent `CommercialPack.pricingPolicyType` itself
/// already sets (TASK-207).
final class ResolvedPackLine {
  const ResolvedPackLine({
    required this.componentId,
    required this.variantId,
    required this.productId,
    required this.quantity,
    required this.isBonusItem,
  });

  /// The `PackComponent.id` this line was resolved from — preserved so a
  /// caller can explain *why* a given variant/quantity is on the pack (e.g.
  /// "componente X exige 2 unidades") without re-walking the composition.
  final String componentId;

  final String variantId;
  final String productId;

  /// How many units of [variantId] one single instance of the owning pack
  /// requires — never itself multiplied by "how many packs the seller
  /// added"; a caller wanting N pack instances multiplies this by N.
  final int quantity;

  /// Whether this line is the one component given away for free under the
  /// owning `CommercialPack.pricingPolicyType.bonusItem` policy — mirrors
  /// `PackComponent.isBonusItem`, carried here only for display (e.g. "item
  /// bônus" badge); the actual price-zeroing is always the pricing engine's
  /// job (`calculatePricing`), never computed from this flag client-side.
  final bool isBonusItem;
}
