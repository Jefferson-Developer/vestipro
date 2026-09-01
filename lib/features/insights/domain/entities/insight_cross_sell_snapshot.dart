import 'insight_cross_sell_category_candidate.dart';

/// Per-customer cross-sell dataset: the categories a group of "similar
/// customers" buys, compared against this customer's own purchase history,
/// used by [CrossSellInsightRule] to suggest categories the customer does
/// not buy yet but similar customers do.
final class InsightCrossSellSnapshot {
  const InsightCrossSellSnapshot({
    required this.customerId,
    required this.organizationId,
    required this.companyId,
    required this.recipientUserId,
    required this.customerName,
    required this.similarityGroupLabel,
    required this.similarityGroupSize,
    this.candidates = const <InsightCrossSellCategoryCandidate>[],
  });

  final String customerId;
  final String organizationId;
  final String companyId;
  final String recipientUserId;
  final String customerName;

  /// Human-readable description of the criterion used to select the
  /// "similar customers" comparison group for this customer (e.g. "mesmo
  /// segmento (Premium) e regiao (Sul)"). Always surfaced in the insight
  /// evidence, per the explainability requirement of the insights engine.
  final String similarityGroupLabel;

  /// Number of customers in the similarity comparison group.
  final int similarityGroupSize;

  /// Candidate categories considered for this customer. Filtering
  /// (already-purchased, unavailable, discontinued) and ranking is done by
  /// the rule, not pre-applied here, so the rule's behavior stays testable
  /// and explicit.
  final List<InsightCrossSellCategoryCandidate> candidates;
}
