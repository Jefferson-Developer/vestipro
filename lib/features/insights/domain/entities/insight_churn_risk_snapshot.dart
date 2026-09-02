/// Per-customer dataset used by [ChurnRiskInsightRule] (TASK-129) to combine
/// three independent signals — decline in purchase frequency, decline in
/// revenue and the customer health score (TASK-062) — into a single,
/// explainable churn-risk score.
final class InsightChurnRiskSnapshot {
  const InsightChurnRiskSnapshot({
    required this.customerId,
    required this.organizationId,
    required this.companyId,
    required this.recipientUserId,
    required this.customerName,
    required this.historicalOrderCount,
    required this.recentPurchaseFrequency,
    required this.historicalPurchaseFrequency,
    required this.recentRevenue,
    required this.historicalRevenue,
    required this.healthScore,
    this.averageTicket,
  });

  final String customerId;
  final String organizationId;
  final String companyId;
  final String recipientUserId;
  final String customerName;

  /// Total number of orders observed within the historical lookback window
  /// used to compute [historicalPurchaseFrequency] and [historicalRevenue].
  /// Gates whether the churn-risk score is reliable enough to be raised (see
  /// [InsightOrganizationSettings.churnRiskMinimumHistoricalOrders]) — a
  /// customer with too little history must not produce a false positive.
  final int historicalOrderCount;

  /// Recent purchase frequency (orders per period, e.g. orders/month),
  /// measured over the most recent observation window.
  final double recentPurchaseFrequency;

  /// Baseline purchase frequency (same unit as [recentPurchaseFrequency]),
  /// measured over the historical comparison window.
  final double historicalPurchaseFrequency;

  /// Revenue recorded in the recent observation window.
  final double recentRevenue;

  /// Baseline revenue recorded in the historical comparison window. Also
  /// used, together with [averageTicket], as the customer's financial
  /// impact base for churn-risk prioritization.
  final double historicalRevenue;

  /// Customer health score (0..100, higher is healthier), computed by
  /// `CustomerScoringService` (TASK-062).
  final int healthScore;

  /// Optional historical average ticket, used as a financial-impact
  /// fallback when [historicalRevenue] is not available.
  final double? averageTicket;

  /// Normalized (0..1) decline in purchase frequency versus the historical
  /// baseline. `0` means no decline (or growth), `1` means purchases have
  /// effectively stopped.
  double get frequencyDeclineRatio => _declineRatio(
    recent: recentPurchaseFrequency,
    historical: historicalPurchaseFrequency,
  );

  /// Normalized (0..1) decline in revenue versus the historical baseline.
  double get revenueDeclineRatio =>
      _declineRatio(recent: recentRevenue, historical: historicalRevenue);

  /// Normalized (0..1) risk contributed by the health score alone: `0` for a
  /// perfect (100) health score, `1` for the worst (0) health score.
  double get healthScoreRiskRatio => (100 - healthScore.clamp(0, 100)) / 100;

  /// Financial impact base (BRL) used to prioritize the churn-risk insight
  /// by the customer's economic weight, per historical revenue with an
  /// average-ticket fallback for customers without a reliable revenue
  /// baseline yet.
  double get financialImpactBase =>
      historicalRevenue > 0 ? historicalRevenue : (averageTicket ?? 0);

  double _declineRatio({required double recent, required double historical}) {
    if (historical <= 0) {
      return 0;
    }
    final ratio = (historical - recent) / historical;
    return ratio.clamp(0, 1);
  }
}
