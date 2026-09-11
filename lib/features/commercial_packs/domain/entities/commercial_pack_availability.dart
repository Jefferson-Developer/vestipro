/// How many full instances of a `CommercialPack` can currently be sold, and
/// (when limited) which component is the bottleneck (TASK-208, EPIC-32) —
/// this is always a client-side, non-authoritative estimate: the seller can
/// still attempt to add the pack, but the real, server-side stock check only
/// ever happens at `submitOrder` time (`functions/src/orders/submit-order.ts`),
/// same "não confiar apenas no cliente" rule every other stock signal in this
/// codebase (`VariantInventoryAvailability`) already follows.
final class CommercialPackAvailability {
  const CommercialPackAvailability({
    required this.packId,
    required this.availableInstances,
    this.shortfalls = const <CommercialPackComponentShortfall>[],
  });

  final String packId;

  /// How many full pack instances are fulfillable right now given every
  /// resolved component's current sellable balance — `0` means the pack
  /// cannot be sold at all today, never a negative number.
  final int availableInstances;

  /// Every resolved line whose own fulfillable-instance count ties
  /// [availableInstances] — i.e. the actual bottleneck(s) explaining why the
  /// pack cannot fulfill more instances right now. Always empty for the
  /// [CommercialPackStockPolicyType.dedicatedStock] policy, which reports a
  /// single pre-assembled balance instead of a per-component breakdown.
  final List<CommercialPackComponentShortfall> shortfalls;

  bool get isFullyAvailable => availableInstances > 0;
}

/// One resolved pack component/variant whose own stock balance is the (or a)
/// limiting factor for how many pack instances are currently fulfillable —
/// used to explain *why* a pack shows as partially/fully unavailable (this
/// task's "explicar por que um pacote está indisponível" requirement).
final class CommercialPackComponentShortfall {
  const CommercialPackComponentShortfall({
    required this.componentId,
    required this.variantId,
    required this.requiredQuantityPerInstance,
    required this.availableQuantity,
  });

  final String componentId;
  final String variantId;

  /// How many units of [variantId] a single pack instance requires.
  final int requiredQuantityPerInstance;

  /// The variant's own currently sellable quantity, across every warehouse
  /// (`VariantInventoryAvailability.totalSellableQuantity`).
  final int availableQuantity;

  /// How many full pack instances this one line alone can fulfill —
  /// `availableQuantity ~/ requiredQuantityPerInstance` — never negative.
  int get fulfillableInstances => requiredQuantityPerInstance <= 0
      ? 0
      : availableQuantity ~/ requiredQuantityPerInstance;
}
