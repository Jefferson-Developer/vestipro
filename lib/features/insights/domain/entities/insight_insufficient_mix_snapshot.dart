import 'insight_insufficient_mix_category_candidate.dart';

/// Per-customer mix dataset: the universe of categories considered for the
/// organization-configured comparison group (segment, region, porte, or a
/// combination), used by [InsufficientMixInsightRule] to detect when a
/// customer buys fewer distinct categories than the group's benchmark.
final class InsightInsufficientMixSnapshot {
  const InsightInsufficientMixSnapshot({
    required this.customerId,
    required this.organizationId,
    required this.companyId,
    required this.recipientUserId,
    required this.customerName,
    required this.comparisonGroupLabel,
    required this.comparisonGroupSize,
    this.segment,
    this.candidates = const <InsightInsufficientMixCategoryCandidate>[],
  });

  final String customerId;
  final String organizationId;
  final String companyId;
  final String recipientUserId;
  final String customerName;

  /// Human-readable description of the criterion used to select the
  /// benchmark comparison group for this customer (e.g. "mesmo segmento
  /// (Premium), regiao (Sul) e porte"), configurable by the organization.
  /// Always surfaced in the insight evidence, per the explainability
  /// requirement of the insights engine.
  final String comparisonGroupLabel;

  /// Number of customers in the comparison group.
  final int comparisonGroupSize;

  /// Segment used to resolve organization-configured category exclusions for
  /// this customer's profile (see
  /// `InsightOrganizationSettings.resolveInsufficientMixExcludedCategoryIds`).
  final String? segment;

  /// Categories considered in the comparison group's universe. Exclusion of
  /// irrelevant categories (per organization configuration) and the mix
  /// benchmark/ratio calculation are performed by the rule, not pre-applied
  /// here, so the rule's behavior stays testable and explicit.
  final List<InsightInsufficientMixCategoryCandidate> candidates;
}
