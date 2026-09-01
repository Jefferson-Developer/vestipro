import '../value_objects/insight_revenue_comparison_mode.dart';

final class InsightOrganizationSettings {
  const InsightOrganizationSettings({
    this.inactivityThresholdDays = 45,
    this.inactivityThresholdDaysBySegment = const <String, int>{},
    this.revenueDropThreshold = 0.30,
    this.revenueDropMinimumBaselineAmount = 1000,
    this.revenueComparisonMode = InsightRevenueComparisonMode.yearOverYear,
    this.customerGrowthMinConsecutivePeriods = 3,
    this.customerGrowthMinimumAverageRate = 0.15,
    this.defaultLifetime = const Duration(days: 7),
  });

  final int inactivityThresholdDays;
  final Map<String, int> inactivityThresholdDaysBySegment;
  final double revenueDropThreshold;
  final double revenueDropMinimumBaselineAmount;
  final InsightRevenueComparisonMode revenueComparisonMode;

  /// Minimum number of consecutive period-over-period growth readings
  /// required before a "growing customer" insight can be raised.
  final int customerGrowthMinConsecutivePeriods;

  /// Minimum average growth rate (e.g. `0.15` = 15%) across the consecutive
  /// periods required before a "growing customer" insight can be raised.
  final double customerGrowthMinimumAverageRate;
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
