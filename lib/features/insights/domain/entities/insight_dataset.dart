import 'insight_abandoned_order_snapshot.dart';
import 'insight_churn_risk_snapshot.dart';
import 'insight_cross_sell_snapshot.dart';
import 'insight_customer_growth_snapshot.dart';
import 'insight_customer_snapshot.dart';
import 'insight_insufficient_mix_snapshot.dart';
import 'insight_organization_settings.dart';
import 'insight_revenue_comparison_snapshot.dart';
import 'insight_sales_rep_below_target_snapshot.dart';
import 'insight_stock_position_snapshot.dart';
import 'insight_up_sell_snapshot.dart';

final class InsightDataset {
  const InsightDataset({
    required this.settings,
    this.customerSnapshots = const <InsightCustomerSnapshot>[],
    this.revenueComparisons = const <InsightRevenueComparisonSnapshot>[],
    this.customerGrowthSnapshots = const <InsightCustomerGrowthSnapshot>[],
    this.crossSellSnapshots = const <InsightCrossSellSnapshot>[],
    this.upSellSnapshots = const <InsightUpSellSnapshot>[],
    this.insufficientMixSnapshots = const <InsightInsufficientMixSnapshot>[],
    this.stockPositionSnapshots = const <InsightStockPositionSnapshot>[],
    this.churnRiskSnapshots = const <InsightChurnRiskSnapshot>[],
    this.abandonedOrderSnapshots = const <InsightAbandonedOrderSnapshot>[],
    this.salesRepBelowTargetSnapshots =
        const <InsightSalesRepBelowTargetSnapshot>[],
  });

  final InsightOrganizationSettings settings;
  final List<InsightCustomerSnapshot> customerSnapshots;
  final List<InsightRevenueComparisonSnapshot> revenueComparisons;
  final List<InsightCustomerGrowthSnapshot> customerGrowthSnapshots;
  final List<InsightCrossSellSnapshot> crossSellSnapshots;
  final List<InsightUpSellSnapshot> upSellSnapshots;
  final List<InsightInsufficientMixSnapshot> insufficientMixSnapshots;
  final List<InsightStockPositionSnapshot> stockPositionSnapshots;
  final List<InsightChurnRiskSnapshot> churnRiskSnapshots;
  final List<InsightAbandonedOrderSnapshot> abandonedOrderSnapshots;
  final List<InsightSalesRepBelowTargetSnapshot> salesRepBelowTargetSnapshots;
}
