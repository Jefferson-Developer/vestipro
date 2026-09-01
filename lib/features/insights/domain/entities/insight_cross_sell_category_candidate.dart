/// A single category-level cross-sell candidate for one customer, computed
/// by comparing the customer against a group of "similar customers" (see
/// [InsightCrossSellSnapshot.similarityGroupLabel] for the exact criteria
/// used, always exposed for explainability — never a black box).
final class InsightCrossSellCategoryCandidate {
  const InsightCrossSellCategoryCandidate({
    required this.categoryId,
    required this.categoryName,
    required this.peerAdoptionRate,
    required this.peerAverageTicket,
    this.alreadyPurchasedByCustomer = false,
    this.isAvailableInCustomerPriceList = true,
    this.isActiveCollection = true,
  });

  final String categoryId;
  final String categoryName;

  /// Fraction (`0`..`1`) of the similar-customers group that purchases this
  /// category.
  final double peerAdoptionRate;

  /// Average ticket for this category among the similar-customers group that
  /// purchases it.
  final double peerAverageTicket;

  /// Whether the target customer already has purchase history in this
  /// category. Candidates where this is `true` are never suggested.
  final bool alreadyPurchasedByCustomer;

  /// Whether this category is available in the target customer's active
  /// price list/catalog. Candidates where this is `false` are never
  /// suggested.
  final bool isAvailableInCustomerPriceList;

  /// Whether this category belongs to a discontinued or out-of-season
  /// collection. Candidates where this is `false` are never suggested.
  final bool isActiveCollection;

  /// Relevance score used to rank candidates: adoption among similar
  /// customers weighted by their average ticket for the category.
  double get relevanceScore => peerAdoptionRate * peerAverageTicket;

  bool get isEligible =>
      !alreadyPurchasedByCustomer &&
      isAvailableInCustomerPriceList &&
      isActiveCollection &&
      peerAdoptionRate > 0;
}
