import 'insight_customer_growth_period.dart';

final class InsightCustomerGrowthSnapshot {
  const InsightCustomerGrowthSnapshot({
    required this.customerId,
    required this.organizationId,
    required this.companyId,
    required this.recipientUserId,
    required this.customerName,
    required this.periods,
    this.topGrowingCategoryId,
    this.topGrowingCategoryName,
    this.topGrowingCategoryRevenueGrowthAmount,
  });

  final String customerId;
  final String organizationId;
  final String companyId;
  final String recipientUserId;
  final String customerName;

  /// Revenue-by-period series, ordered chronologically (oldest first, most
  /// recent period last).
  final List<InsightCustomerGrowthPeriod> periods;
  final String? topGrowingCategoryId;
  final String? topGrowingCategoryName;
  final double? topGrowingCategoryRevenueGrowthAmount;
}
