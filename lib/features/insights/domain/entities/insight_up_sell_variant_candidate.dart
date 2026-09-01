/// A single variant-level quantity suggestion for an up-sell opportunity,
/// always capped by the real stock balance of the variant (TASK-090) so the
/// engine never suggests a quantity that cannot actually be fulfilled.
final class InsightUpSellVariantCandidate {
  const InsightUpSellVariantCandidate({
    required this.variantId,
    required this.variantLabel,
    required this.desiredAdditionalQuantity,
    required this.availableStock,
  });

  final String variantId;

  /// Human-readable variant identification (e.g. "Azul - M").
  final String variantLabel;

  /// Additional quantity that would close the gap towards the comparison
  /// group's average, before checking real stock availability.
  final int desiredAdditionalQuantity;

  /// Real stock balance available for this variant at evaluation time.
  final int availableStock;

  /// Additional quantity actually suggested, never exceeding
  /// [availableStock] and never negative.
  int get suggestedAdditionalQuantity {
    if (desiredAdditionalQuantity <= 0 || availableStock <= 0) {
      return 0;
    }
    return desiredAdditionalQuantity < availableStock
        ? desiredAdditionalQuantity
        : availableStock;
  }

  bool get hasSuggestion => suggestedAdditionalQuantity > 0;
}
