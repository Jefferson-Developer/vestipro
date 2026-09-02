/// Per-seller dataset used by [SalesRepBelowTargetInsightRule] (TASK-131) to
/// detect a sales representative whose current pace, extrapolated linearly
/// to the end of the period, would not reach the goal cadastrado for that
/// period (TASK-115, EPIC-15).
///
/// [elapsedRelevantDays]/[totalRelevantDays] are already resolved upstream
/// (TASK-133 aggregation layer) to whichever counting convention the
/// organization configured — calendar days or business days only — so this
/// rule never needs a holiday calendar of its own; it only ever compares two
/// day counts already expressed in the same unit.
///
/// [recipientUserId] must always be resolved server-side to the seller's
/// *current sales manager* (never the seller themselves): the insight
/// repository (TASK-121) filters strictly by `recipientUserId` equality, so
/// this field alone is what restricts this insight's visibility to
/// `SALES_MANAGER`/`ADMIN` and guarantees a manager only ever receives
/// insights about their own team — a manager for a different team, or the
/// seller in question, must never be assigned this value.
final class InsightSalesRepBelowTargetSnapshot {
  const InsightSalesRepBelowTargetSnapshot({
    required this.sellerId,
    required this.organizationId,
    required this.companyId,
    required this.recipientUserId,
    required this.sellerName,
    required this.periodLabel,
    required this.periodStartDate,
    required this.periodEndDate,
    required this.targetValue,
    required this.realizedValue,
    required this.elapsedRelevantDays,
    required this.totalRelevantDays,
  });

  final String sellerId;
  final String organizationId;
  final String companyId;

  /// The sales manager (or admin acting as one) who will see this insight —
  /// see this class's own doc comment for why this must never be the
  /// seller's own id.
  final String recipientUserId;

  final String sellerName;

  /// Human-readable label for the target's period (e.g. "Setembro/2026"),
  /// always exposed in the insight evidence — never a black box.
  final String periodLabel;

  final DateTime periodStartDate;
  final DateTime periodEndDate;

  /// Goal cadastrado (TASK-115) for [sellerId] in this period.
  final double targetValue;

  /// Realized value so far in this period, as of the aggregation's cutoff —
  /// never independently recomputed by this rule.
  final double realizedValue;

  /// Relevant days (calendar or business days, per organization
  /// configuration) already elapsed in the period, as of the aggregation's
  /// cutoff.
  final int elapsedRelevantDays;

  /// Total relevant days (same counting convention as
  /// [elapsedRelevantDays]) in the whole period.
  final int totalRelevantDays;

  /// Relevant days still left in the period, never negative.
  int get remainingRelevantDays => (totalRelevantDays - elapsedRelevantDays)
      .clamp(0, totalRelevantDays <= 0 ? 0 : totalRelevantDays);

  /// Average realized value per relevant day so far. `0` when no relevant
  /// day has elapsed yet (guarded by
  /// [InsightOrganizationSettings.sellerBelowTargetMinimumElapsedDays]
  /// before this is ever used to raise an insight).
  double get currentDailyPace =>
      elapsedRelevantDays <= 0 ? 0.0 : realizedValue / elapsedRelevantDays;

  /// Daily pace still required in [remainingRelevantDays] to close the gap
  /// between [realizedValue] and [targetValue]. `double.infinity` when there
  /// is a positive gap but no relevant day left to close it.
  double get requiredDailyPaceForRemainingDays {
    final remaining = remainingRelevantDays;
    final gap = targetValue - realizedValue;
    if (gap <= 0) {
      return 0.0;
    }
    if (remaining <= 0) {
      return double.infinity;
    }
    return gap / remaining;
  }

  /// Simple linear projection of the period's final result: the seller's
  /// [currentDailyPace] held constant for the whole period.
  double get projectedValue => currentDailyPace * totalRelevantDays;

  /// [projectedValue] as a % of [targetValue] (zero-target guard mirrors
  /// `TargetProgressViewModel.achievementPercentage`, EPIC-15).
  double get projectedAchievementPercentage {
    if (targetValue <= 0) {
      return projectedValue > 0 ? 100.0 : 0.0;
    }
    return (projectedValue / targetValue) * 100;
  }

  /// Normalized (0..1) shortfall of [projectedAchievementPercentage] against
  /// a full 100% achievement — `0` when the projection meets or exceeds the
  /// goal, `1` when the projection indicates no progress at all.
  double get underAchievementRatio =>
      (1 - (projectedAchievementPercentage / 100)).clamp(0.0, 1.0);
}
