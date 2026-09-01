import 'insight_up_sell_category_candidate.dart';

/// Per-customer up-sell dataset: for each category the customer already
/// buys, compares the customer's own average ticket/quantity per order
/// against a group of similar customers with higher volume in that same
/// category, used by [UpSellInsightRule] to suggest expanding the grade
/// already purchased.
final class InsightUpSellSnapshot {
  const InsightUpSellSnapshot({
    required this.customerId,
    required this.organizationId,
    required this.companyId,
    required this.recipientUserId,
    required this.customerName,
    required this.comparisonGroupLabel,
    required this.comparisonGroupSize,
    this.candidates = const <InsightUpSellCategoryCandidate>[],
  });

  final String customerId;
  final String organizationId;
  final String companyId;
  final String recipientUserId;
  final String customerName;

  /// Human-readable description of the criterion used to select the
  /// higher-volume similar-customers comparison group for this customer
  /// (same similarity basis used by cross-sell, TASK-125). Always surfaced
  /// in the insight evidence, per the explainability requirement of the
  /// insights engine.
  final String comparisonGroupLabel;

  /// Number of customers in the comparison group.
  final int comparisonGroupSize;

  /// Candidate categories already purchased by the customer. Eligibility
  /// filtering (below comparison group average) and stock-aware quantity
  /// suggestions are computed by the rule, not pre-applied here, so the
  /// rule's behavior stays testable and explicit.
  final List<InsightUpSellCategoryCandidate> candidates;
}
