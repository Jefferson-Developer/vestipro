import 'insight_up_sell_variant_candidate.dart';

/// A category the customer already has purchase history in (unlike
/// cross-sell, TASK-125, which only considers categories the customer does
/// not buy yet), compared against a group of similar customers with higher
/// volume in the same category, used by [UpSellInsightRule] to suggest
/// expanding the quantity/ticket already purchased.
final class InsightUpSellCategoryCandidate {
  const InsightUpSellCategoryCandidate({
    required this.categoryId,
    required this.categoryName,
    required this.customerAverageTicket,
    required this.customerAverageQuantity,
    required this.peerAverageTicket,
    required this.peerAverageQuantity,
    this.variantCandidates = const <InsightUpSellVariantCandidate>[],
  });

  final String categoryId;
  final String categoryName;

  /// This customer's own average ticket per order in this category.
  final double customerAverageTicket;

  /// This customer's own average quantity per order in this category.
  final double customerAverageQuantity;

  /// Average ticket per order in this category among the higher-volume
  /// similar-customers comparison group (same comparison basis used by
  /// cross-sell, TASK-125).
  final double peerAverageTicket;

  /// Average quantity per order in this category among the higher-volume
  /// similar-customers comparison group.
  final double peerAverageQuantity;

  /// Variant-level suggestions (within this category) for the "Sugerir
  /// grade ampliada" quick action, each already checked against real stock
  /// availability.
  final List<InsightUpSellVariantCandidate> variantCandidates;

  /// Percentage gap between this customer's average ticket and the
  /// comparison group's average ticket in this category. Positive when the
  /// customer is below the group average.
  double get ticketGapPercentage {
    if (peerAverageTicket <= 0) {
      return 0;
    }
    return (peerAverageTicket - customerAverageTicket) / peerAverageTicket;
  }

  /// A category only qualifies for up-sell when the customer already has
  /// purchase history in it (`customerAverageTicket > 0`) and sits strictly
  /// below the comparison group's average ticket.
  bool get isEligible =>
      customerAverageTicket > 0 && customerAverageTicket < peerAverageTicket;
}
