import 'package:injectable/injectable.dart';

import 'domain/rules/abandoned_order_insight_rule.dart';
import 'domain/rules/churn_risk_insight_rule.dart';
import 'domain/rules/cross_sell_insight_rule.dart';
import 'domain/rules/growing_customer_insight_rule.dart';
import 'domain/rules/high_stock_low_turnover_insight_rule.dart';
import 'domain/rules/inactive_customer_insight_rule.dart';
import 'domain/rules/insufficient_mix_insight_rule.dart';
import 'domain/rules/replenishment_suggestion_insight_rule.dart';
import 'domain/rules/revenue_drop_insight_rule.dart';
import 'domain/rules/up_sell_insight_rule.dart';
import 'domain/services/insight_rule.dart';

@module
abstract class InsightModule {
  @lazySingleton
  List<InsightRule> insightRules(
    InactiveCustomerInsightRule inactiveCustomerRule,
    RevenueDropInsightRule revenueDropRule,
    GrowingCustomerInsightRule growingCustomerRule,
    CrossSellInsightRule crossSellRule,
    UpSellInsightRule upSellRule,
    InsufficientMixInsightRule insufficientMixRule,
    HighStockLowTurnoverInsightRule highStockLowTurnoverRule,
    ReplenishmentSuggestionInsightRule replenishmentSuggestionRule,
    ChurnRiskInsightRule churnRiskRule,
    AbandonedDraftOrderInsightRule abandonedOrderRule,
  ) {
    return <InsightRule>[
      inactiveCustomerRule,
      revenueDropRule,
      growingCustomerRule,
      crossSellRule,
      upSellRule,
      insufficientMixRule,
      highStockLowTurnoverRule,
      replenishmentSuggestionRule,
      churnRiskRule,
      abandonedOrderRule,
    ];
  }
}
