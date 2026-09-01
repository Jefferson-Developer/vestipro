import 'insight_cross_sell_snapshot.dart';
import 'insight_customer_growth_snapshot.dart';
import 'insight_customer_snapshot.dart';
import 'insight_organization_settings.dart';
import 'insight_revenue_comparison_snapshot.dart';

final class InsightDataset {
  const InsightDataset({
    required this.settings,
    this.customerSnapshots = const <InsightCustomerSnapshot>[],
    this.revenueComparisons = const <InsightRevenueComparisonSnapshot>[],
    this.customerGrowthSnapshots = const <InsightCustomerGrowthSnapshot>[],
    this.crossSellSnapshots = const <InsightCrossSellSnapshot>[],
  });

  final InsightOrganizationSettings settings;
  final List<InsightCustomerSnapshot> customerSnapshots;
  final List<InsightRevenueComparisonSnapshot> revenueComparisons;
  final List<InsightCustomerGrowthSnapshot> customerGrowthSnapshots;
  final List<InsightCrossSellSnapshot> crossSellSnapshots;
}
