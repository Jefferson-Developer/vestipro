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
    this.upSellMinimumTicketGapPercentage = 0.15,
    this.insufficientMixThresholdPercentage = 0.7,
    this.insufficientMixExcludedCategoryIds = const <String>{},
    this.insufficientMixExcludedCategoryIdsBySegment =
        const <String, Set<String>>{},
    this.highStockCoverageDaysThreshold = 60,
    this.highStockCoverageDaysThresholdByCategory = const <String, double>{},
    this.lowTurnoverIndexThreshold = 0.5,
    this.lowTurnoverIndexThresholdByCategory = const <String, double>{},
    this.replenishmentLowCoverageDaysThreshold = 10,
    this.replenishmentLowCoverageDaysThresholdByCategory =
        const <String, double>{},
    this.replenishmentHighTurnoverIndexThreshold = 1.5,
    this.replenishmentHighTurnoverIndexThresholdByCategory =
        const <String, double>{},
    this.churnRiskFrequencyWeight = 0.35,
    this.churnRiskValueWeight = 0.35,
    this.churnRiskHealthScoreWeight = 0.30,
    this.churnRiskMinimumHistoricalOrders = 3,
    this.churnRiskMediumThreshold = 0.35,
    this.churnRiskHighThreshold = 0.55,
    this.churnRiskCriticalThreshold = 0.75,
    this.abandonedOrderSavedCartThresholdHours = 24,
    this.abandonedOrderAbandonedThresholdHours = 72,
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

  /// Minimum percentage gap (e.g. `0.15` = 15%) between a customer's average
  /// ticket in a category and the higher-volume comparison group's average
  /// ticket in that same category, required before an "up-sell" insight can
  /// be raised — ensures the insight only surfaces a relevant and
  /// sustainable difference, never noise.
  final double upSellMinimumTicketGapPercentage;

  /// Fraction (e.g. `0.7` = 70%) of the comparison group's mix benchmark
  /// (average number of distinct categories purchased) a customer must reach
  /// before an "insufficient mix" insight stops being raised.
  final double insufficientMixThresholdPercentage;

  /// Categories excluded from the mix benchmark calculation for every
  /// customer (e.g. a category exclusive to another sales channel),
  /// configurable by the organization without code changes.
  final Set<String> insufficientMixExcludedCategoryIds;

  /// Additional categories excluded from the mix benchmark calculation only
  /// for customers of a given segment/profile, merged with
  /// [insufficientMixExcludedCategoryIds].
  final Map<String, Set<String>> insufficientMixExcludedCategoryIdsBySegment;

  /// Minimum stock coverage, in days, above which a product/variant is
  /// considered to have "high stock" for the liquidation-candidate rule
  /// ([HighStockLowTurnoverInsightRule]).
  final double highStockCoverageDaysThreshold;

  /// Category-specific overrides for [highStockCoverageDaysThreshold] (basic,
  /// moda and fashion categories have distinct expected coverage).
  final Map<String, double> highStockCoverageDaysThresholdByCategory;

  /// Maximum turnover index below which a product/variant is considered to
  /// have "low turnover" for the liquidation-candidate rule
  /// ([HighStockLowTurnoverInsightRule]).
  final double lowTurnoverIndexThreshold;

  /// Category-specific overrides for [lowTurnoverIndexThreshold].
  final Map<String, double> lowTurnoverIndexThresholdByCategory;

  /// Maximum stock coverage, in days, below which a product/variant is at
  /// risk of rupture for the replenishment rule
  /// ([ReplenishmentSuggestionInsightRule]).
  final double replenishmentLowCoverageDaysThreshold;

  /// Category-specific overrides for [replenishmentLowCoverageDaysThreshold].
  final Map<String, double> replenishmentLowCoverageDaysThresholdByCategory;

  /// Minimum turnover index above which a product/variant is considered
  /// high-turnover for the replenishment rule
  /// ([ReplenishmentSuggestionInsightRule]).
  final double replenishmentHighTurnoverIndexThreshold;

  /// Category-specific overrides for
  /// [replenishmentHighTurnoverIndexThreshold].
  final Map<String, double> replenishmentHighTurnoverIndexThresholdByCategory;

  /// Weight (0..1) of the purchase-frequency-decline signal in the
  /// churn-risk composition score ([ChurnRiskInsightRule]).
  final double churnRiskFrequencyWeight;

  /// Weight (0..1) of the revenue-decline signal in the churn-risk
  /// composition score.
  final double churnRiskValueWeight;

  /// Weight (0..1) of the customer health-score signal (TASK-062) in the
  /// churn-risk composition score.
  final double churnRiskHealthScoreWeight;

  /// Minimum number of historical orders a customer must have for the
  /// churn-risk score to be considered reliable. Customers below this
  /// threshold never raise a churn-risk insight, avoiding false positives
  /// caused by insufficient purchase history.
  final int churnRiskMinimumHistoricalOrders;

  /// Minimum composed risk score (0..1) required to classify a customer as
  /// "medio" risk and raise a churn-risk insight. Scores below this
  /// threshold are considered "baixo" risk and are not surfaced.
  final double churnRiskMediumThreshold;

  /// Minimum composed risk score (0..1) required to classify a customer as
  /// "alto" risk.
  final double churnRiskHighThreshold;

  /// Minimum composed risk score (0..1) required to classify a customer as
  /// "critico" risk.
  final double churnRiskCriticalThreshold;

  /// Minimum hours since a draft order's content (items/quantities) was last
  /// changed before it is raised as a "carrinho salvo" (saved cart) insight
  /// ([AbandonedDraftOrderInsightRule]).
  final double abandonedOrderSavedCartThresholdHours;

  /// Minimum hours since a draft order's content was last changed before it
  /// is raised as a "pedido abandonado" (abandoned order) insight instead of
  /// the lower "carrinho salvo" severity.
  final double abandonedOrderAbandonedThresholdHours;

  final Duration defaultLifetime;

  int resolveInactivityThreshold(String? segment) {
    final normalized = segment?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return inactivityThresholdDays;
    }
    return inactivityThresholdDaysBySegment[normalized] ??
        inactivityThresholdDays;
  }

  /// Resolves the effective set of category ids excluded from the mix
  /// benchmark calculation for the given customer [segment], merging the
  /// organization-wide exclusions with any segment-specific ones.
  Set<String> resolveInsufficientMixExcludedCategoryIds(String? segment) {
    final normalized = segment?.trim().toLowerCase();
    final bySegment = normalized == null
        ? null
        : insufficientMixExcludedCategoryIdsBySegment[normalized];
    if (bySegment == null || bySegment.isEmpty) {
      return insufficientMixExcludedCategoryIds;
    }
    return <String>{...insufficientMixExcludedCategoryIds, ...bySegment};
  }

  /// Resolves the effective coverage-days threshold above which a
  /// product/variant of [categoryId] is considered to have "high stock",
  /// falling back to [highStockCoverageDaysThreshold] when there is no
  /// category-specific override.
  double resolveHighStockCoverageDaysThreshold(String? categoryId) {
    return _resolveByCategory(
      categoryId,
      highStockCoverageDaysThresholdByCategory,
      highStockCoverageDaysThreshold,
    );
  }

  /// Resolves the effective turnover-index threshold below which a
  /// product/variant of [categoryId] is considered to have "low turnover",
  /// falling back to [lowTurnoverIndexThreshold] when there is no
  /// category-specific override.
  double resolveLowTurnoverIndexThreshold(String? categoryId) {
    return _resolveByCategory(
      categoryId,
      lowTurnoverIndexThresholdByCategory,
      lowTurnoverIndexThreshold,
    );
  }

  /// Resolves the effective coverage-days threshold below which a
  /// product/variant of [categoryId] is at risk of rupture, falling back to
  /// [replenishmentLowCoverageDaysThreshold] when there is no
  /// category-specific override.
  double resolveReplenishmentLowCoverageDaysThreshold(String? categoryId) {
    return _resolveByCategory(
      categoryId,
      replenishmentLowCoverageDaysThresholdByCategory,
      replenishmentLowCoverageDaysThreshold,
    );
  }

  /// Resolves the effective turnover-index threshold above which a
  /// product/variant of [categoryId] is considered high-turnover, falling
  /// back to [replenishmentHighTurnoverIndexThreshold] when there is no
  /// category-specific override.
  double resolveReplenishmentHighTurnoverIndexThreshold(String? categoryId) {
    return _resolveByCategory(
      categoryId,
      replenishmentHighTurnoverIndexThresholdByCategory,
      replenishmentHighTurnoverIndexThreshold,
    );
  }

  double _resolveByCategory(
    String? categoryId,
    Map<String, double> thresholdsByCategory,
    double fallback,
  ) {
    final normalized = categoryId?.trim();
    if (normalized == null || normalized.isEmpty) {
      return fallback;
    }
    return thresholdsByCategory[normalized] ?? fallback;
  }
}
