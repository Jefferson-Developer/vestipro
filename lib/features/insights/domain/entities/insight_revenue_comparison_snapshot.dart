import '../value_objects/insight_revenue_comparison_mode.dart';

final class InsightRevenueComparisonSnapshot {
  const InsightRevenueComparisonSnapshot({
    required this.customerId,
    required this.organizationId,
    required this.companyId,
    required this.recipientUserId,
    required this.customerName,
    required this.mode,
    required this.currentPeriodRevenue,
    required this.previousEquivalentRevenue,
    required this.currentPeriodKey,
    required this.previousPeriodKey,
    this.currentSeasonCode,
    this.previousSeasonCode,
    this.topCategoryId,
    this.topCategoryName,
    this.topCategoryRevenueDropAmount,
  });

  final String customerId;
  final String organizationId;
  final String companyId;
  final String recipientUserId;
  final String customerName;
  final InsightRevenueComparisonMode mode;
  final double currentPeriodRevenue;
  final double previousEquivalentRevenue;
  final String currentPeriodKey;
  final String previousPeriodKey;
  final String? currentSeasonCode;
  final String? previousSeasonCode;
  final String? topCategoryId;
  final String? topCategoryName;
  final double? topCategoryRevenueDropAmount;

  double get absoluteDrop => previousEquivalentRevenue - currentPeriodRevenue;

  double get dropPercentage {
    if (previousEquivalentRevenue <= 0) {
      return 0;
    }
    return absoluteDrop / previousEquivalentRevenue;
  }

  bool get isSeasonallyEquivalent {
    if (currentSeasonCode == null || previousSeasonCode == null) {
      return true;
    }
    return currentSeasonCode == previousSeasonCode;
  }
}
