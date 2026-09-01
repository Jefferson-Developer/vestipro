final class InsightCustomerGrowthPeriod {
  const InsightCustomerGrowthPeriod({
    required this.periodKey,
    required this.revenue,
    this.hasOutlierOrder = false,
    this.outlierAdjustedRevenue,
  });

  final String periodKey;
  final double revenue;

  /// Whether this period's [revenue] includes at least one order considered
  /// atypical (far above the customer's historical pattern).
  final bool hasOutlierOrder;

  /// Revenue for this period once the atypical order(s) are excluded. Only
  /// meaningful when [hasOutlierOrder] is `true`.
  final double? outlierAdjustedRevenue;

  /// Revenue used to compute the growth trend: when the period carries an
  /// outlier order, the outlier-adjusted revenue is used instead of the raw
  /// [revenue], so a single atypical order cannot manufacture a false growth
  /// trend for the customer.
  double get trendRevenue =>
      hasOutlierOrder ? (outlierAdjustedRevenue ?? revenue) : revenue;
}
