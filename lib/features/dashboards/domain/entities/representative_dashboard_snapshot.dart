import '../../../crm/domain/entities/crm_task.dart';
import 'executive_dashboard_metric.dart';
import 'representative_customer_highlight.dart';

final class RepresentativeDashboardSnapshot {
  const RepresentativeDashboardSnapshot({
    required this.salesToday,
    required this.salesMonth,
    required this.targetAchievement,
    required this.portfolioPositivation,
    required this.teamRank,
    required this.followUps,
    required this.customers,
    required this.lastUpdatedAt,
    required this.isFromLocalCache,
  });

  final ExecutiveDashboardMetric salesToday;
  final ExecutiveDashboardMetric salesMonth;
  final ExecutiveDashboardMetric targetAchievement;
  final ExecutiveDashboardMetric portfolioPositivation;
  final ExecutiveDashboardMetric teamRank;
  final List<CrmTask> followUps;
  final List<RepresentativeCustomerHighlight> customers;
  final DateTime? lastUpdatedAt;
  final bool isFromLocalCache;
}
