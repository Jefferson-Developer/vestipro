/// Per-product/variant stock position dataset, used by both
/// `HighStockLowTurnoverInsightRule` and `ReplenishmentSuggestionInsightRule`
/// to detect opposite risk signals from the same underlying stock indicators
/// (TASK-090 saldo por variante, TASK-094 indicadores de giro de estoque):
/// excess stock parked with low turnover on one side, and high-turnover
/// items at risk of stockout on the other. Sharing a single snapshot shape
/// keeps both rules reading the exact same evidence, which is what
/// guarantees they never fire for the same product/variant in the same
/// cycle (their threshold conditions are, by construction, mutually
/// exclusive).
final class InsightStockPositionSnapshot {
  const InsightStockPositionSnapshot({
    required this.productId,
    this.variantId,
    required this.organizationId,
    required this.companyId,
    required this.recipientUserId,
    required this.productName,
    this.variantLabel,
    required this.categoryId,
    required this.categoryName,
    required this.currentStockQuantity,
    required this.coverageDays,
    required this.turnoverIndex,
    required this.daysWithoutRelevantSale,
    required this.averageDailyConsumption,
    required this.suggestedReorderPointQuantity,
    this.isDiscontinued = false,
  });

  final String productId;

  /// Variant identifier, when the stock position is tracked at variant
  /// level (color/size). Null when only the product-level aggregate is
  /// available.
  final String? variantId;
  final String organizationId;
  final String companyId;
  final String recipientUserId;
  final String productName;
  final String? variantLabel;
  final String categoryId;
  final String categoryName;

  /// Current stock balance (units), per TASK-090.
  final int currentStockQuantity;

  /// Estimated number of days the current balance covers at the recent
  /// average consumption rate (per TASK-094 turnover indicators).
  final double coverageDays;

  /// Turnover index for the evaluated period (per TASK-094); higher values
  /// mean the stock rotates faster.
  final double turnoverIndex;

  /// Days elapsed since the last sale considered relevant (non-negligible
  /// quantity) for this product/variant.
  final int daysWithoutRelevantSale;

  /// Average daily consumption (units/day) used upstream to derive
  /// [suggestedReorderPointQuantity].
  final double averageDailyConsumption;

  /// Suggested reorder point (units), computed upstream from the recent
  /// average consumption (TASK-133 aggregation layer). Exposed as evidence
  /// only — never recomputed by the rule, so the aggregation logic stays
  /// centralized server-side.
  final double suggestedReorderPointQuantity;

  /// Whether the product/variant is discontinued or outside the current
  /// active collection. Excluded from the replenishment rule, but still
  /// eligible for the high-stock/low-turnover liquidation-candidate rule.
  final bool isDiscontinued;
}
