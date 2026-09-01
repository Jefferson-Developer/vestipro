import '../value_objects/insight_revenue_comparison_mode.dart';

final class InsightOrganizationSettings {
  const InsightOrganizationSettings({
    this.inactivityThresholdDays = 45,
    this.inactivityThresholdDaysBySegment = const <String, int>{},
    this.revenueDropThreshold = 0.30,
    this.revenueDropMinimumBaselineAmount = 1000,
    this.revenueComparisonMode = InsightRevenueComparisonMode.yearOverYear,
    this.defaultLifetime = const Duration(days: 7),
  });

  final int inactivityThresholdDays;
  final Map<String, int> inactivityThresholdDaysBySegment;
  final double revenueDropThreshold;
  final double revenueDropMinimumBaselineAmount;
  final InsightRevenueComparisonMode revenueComparisonMode;
  final Duration defaultLifetime;

  int resolveInactivityThreshold(String? segment) {
    final normalized = segment?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return inactivityThresholdDays;
    }
    return inactivityThresholdDaysBySegment[normalized] ??
        inactivityThresholdDays;
  }
}
