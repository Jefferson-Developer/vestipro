import 'package:injectable/injectable.dart';

import 'domain/rules/inactive_customer_insight_rule.dart';
import 'domain/rules/revenue_drop_insight_rule.dart';
import 'domain/services/insight_rule.dart';

@module
abstract class InsightModule {
  @lazySingleton
  List<InsightRule> insightRules(
    InactiveCustomerInsightRule inactiveCustomerRule,
    RevenueDropInsightRule revenueDropRule,
  ) {
    return <InsightRule>[inactiveCustomerRule, revenueDropRule];
  }
}
