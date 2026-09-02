/// A single category considered in the mix-benchmark universe for one
/// customer, used by [InsufficientMixInsightRule] to compare how many
/// distinct categories the customer buys against the comparison group's
/// benchmark.
final class InsightInsufficientMixCategoryCandidate {
  const InsightInsufficientMixCategoryCandidate({
    required this.categoryId,
    required this.categoryName,
    required this.peerAdoptionRate,
    this.purchasedByCustomer = false,
  });

  final String categoryId;
  final String categoryName;

  /// Fraction (`0`..`1`) of the comparison group that purchases this
  /// category. By linearity of expectation, the sum of this value across the
  /// whole category universe equals the group's average number of distinct
  /// categories purchased per customer (the mix benchmark) — always
  /// explainable, never a black box.
  final double peerAdoptionRate;

  /// Whether the target customer already has purchase history in this
  /// category within the evaluated period.
  final bool purchasedByCustomer;
}
