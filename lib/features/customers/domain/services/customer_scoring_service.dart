import '../entities/customer.dart';
import '../value_objects/customer_health_score_band.dart';
import '../value_objects/customer_score_data_coverage.dart';

const customerScoringFormulaVersion = 'customer_score_v1_2026_08_24';

/// Formula v1 (daily Cloud Function source of truth):
///
/// Commercial score with order signals:
/// `40% purchase recency + 30% purchase frequency 12m + 30% revenue 12m`.
/// Revenue is normalized against BRL 50k until org-specific percentiles exist.
///
/// Commercial score without order signals:
/// `50% CRM/registration recency + 25% CRM frequency 90d + 25% registration
/// freshness`, capped at 60 and tagged as degraded coverage so TASK-063 does
/// not treat it as strong buying evidence.
///
/// Health score with order signals:
/// `45% purchase recency + 25% revenue trend + 20% CRM recency + 10% overdue
/// follow-up hygiene`.
///
/// Health score without order signals:
/// `55% CRM/registration recency + 25% registration/status freshness + 20%
/// overdue follow-up hygiene`.
///
/// Bands: healthy >= 75, attention 50..74, risk < 50.
final class CustomerScoringService {
  const CustomerScoringService();

  static const int fallbackCommercialScoreCap = 60;

  CustomerScoringResult calculate(CustomerScoringInput input) {
    final customer = input.customer;
    final activities = input.crmActivities
        .where(
          (activity) =>
              activity.organizationId == customer.organizationId &&
              activity.customerId == customer.id,
        )
        .toList(growable: false);
    final hasOrderSignals = _hasOrderSignals(input);
    final coverage = hasOrderSignals
        ? CustomerScoreDataCoverage.ordersAndCrm
        : activities.isEmpty
        ? CustomerScoreDataCoverage.registrationOnly
        : CustomerScoreDataCoverage.crmOnly;
    final commercialScore = hasOrderSignals
        ? _commercialScoreWithOrders(input, activities)
        : _commercialScoreWithoutOrders(input, activities);
    final healthScore = hasOrderSignals
        ? _healthScoreWithOrders(input, activities)
        : _healthScoreWithoutOrders(input, activities);

    return CustomerScoringResult(
      commercialScore: commercialScore,
      healthScore: healthScore,
      healthScoreBand: classifyHealthScore(healthScore),
      scoreUpdatedAt: input.now,
      scoreFormulaVersion: customerScoringFormulaVersion,
      scoreDataCoverage: coverage,
    );
  }

  static CustomerHealthScoreBand classifyHealthScore(int value) {
    final normalized = value.clamp(0, 100);
    if (normalized >= 75) return CustomerHealthScoreBand.healthy;
    if (normalized >= 50) return CustomerHealthScoreBand.attention;
    return CustomerHealthScoreBand.risk;
  }

  bool _hasOrderSignals(CustomerScoringInput input) {
    return input.customer.lastPurchaseAt != null ||
        input.purchaseCountLast12Months != null ||
        input.revenueLast12Months != null ||
        input.currentPeriodRevenue != null ||
        input.previousPeriodRevenue != null;
  }

  int _commercialScoreWithOrders(
    CustomerScoringInput input,
    List<CustomerScoringActivitySignal> activities,
  ) {
    final purchaseRecency = _purchaseRecencyScore(
      _ageDays(
        input.customer.lastPurchaseAt ?? _latestActivityAt(activities),
        input.now,
      ),
    );
    final frequency = _purchaseFrequencyScore(
      input.purchaseCountLast12Months,
      input.customer.lastPurchaseAt,
    );
    final value = _revenueScore(
      input.revenueLast12Months,
      fallbackPotential: input.customer.potential,
    );
    return _weightedScore(<_WeightedScore>[
      _WeightedScore(purchaseRecency, 0.40),
      _WeightedScore(frequency, 0.30),
      _WeightedScore(value, 0.30),
    ]);
  }

  int _commercialScoreWithoutOrders(
    CustomerScoringInput input,
    List<CustomerScoringActivitySignal> activities,
  ) {
    final recency = _crmRecencyScore(
      _ageDays(
        _latestActivityAt(activities) ?? input.customer.registeredAt,
        input.now,
      ),
      hasActualCrmActivity: activities.isNotEmpty,
    );
    final frequency = _crmFrequencyScore(
      _activityCountSince(
        activities,
        input.now.subtract(const Duration(days: 90)),
      ),
    );
    final freshness = _registrationFreshnessScore(
      _ageDays(input.customer.registeredAt, input.now),
      input.customer.status.name,
    );
    final score = _weightedScore(<_WeightedScore>[
      _WeightedScore(recency, 0.50),
      _WeightedScore(frequency, 0.25),
      _WeightedScore(freshness, 0.25),
    ]);
    return score > fallbackCommercialScoreCap
        ? fallbackCommercialScoreCap
        : score;
  }

  int _healthScoreWithOrders(
    CustomerScoringInput input,
    List<CustomerScoringActivitySignal> activities,
  ) {
    final purchaseRecency = _purchaseRecencyScore(
      _ageDays(
        input.customer.lastPurchaseAt ?? _latestActivityAt(activities),
        input.now,
      ),
    );
    final trend = _revenueTrendScore(
      current: input.currentPeriodRevenue,
      previous: input.previousPeriodRevenue,
    );
    final crmRecency = _crmRecencyScore(
      _ageDays(
        _latestActivityAt(activities) ?? input.customer.registeredAt,
        input.now,
      ),
      hasActualCrmActivity: activities.isNotEmpty,
    );
    final followUps = _followUpHygieneScore(input.overdueFollowUps);
    return _weightedScore(<_WeightedScore>[
      _WeightedScore(purchaseRecency, 0.45),
      _WeightedScore(trend, 0.25),
      _WeightedScore(crmRecency, 0.20),
      _WeightedScore(followUps, 0.10),
    ]);
  }

  int _healthScoreWithoutOrders(
    CustomerScoringInput input,
    List<CustomerScoringActivitySignal> activities,
  ) {
    final recency = _crmRecencyScore(
      _ageDays(
        _latestActivityAt(activities) ?? input.customer.registeredAt,
        input.now,
      ),
      hasActualCrmActivity: activities.isNotEmpty,
    );
    final freshness = _registrationFreshnessScore(
      _ageDays(input.customer.registeredAt, input.now),
      input.customer.status.name,
    );
    final followUps = _followUpHygieneScore(input.overdueFollowUps);
    return _weightedScore(<_WeightedScore>[
      _WeightedScore(recency, 0.55),
      _WeightedScore(freshness, 0.25),
      _WeightedScore(followUps, 0.20),
    ]);
  }

  int? _ageDays(DateTime? date, DateTime now) {
    if (date == null) return null;
    return now.toUtc().difference(date.toUtc()).inDays;
  }

  DateTime? _latestActivityAt(List<CustomerScoringActivitySignal> activities) {
    DateTime? latest;
    for (final activity in activities) {
      if (latest == null || activity.occurredAt.isAfter(latest)) {
        latest = activity.occurredAt;
      }
    }
    return latest;
  }

  int _activityCountSince(
    List<CustomerScoringActivitySignal> activities,
    DateTime threshold,
  ) {
    return activities
        .where((activity) => !activity.occurredAt.isBefore(threshold))
        .length;
  }

  double _purchaseRecencyScore(int? days) {
    if (days == null) return 15;
    if (days <= 30) return 100;
    if (days <= 90) return 80;
    if (days <= 180) return 55;
    if (days <= 365) return 30;
    return 15;
  }

  double _crmRecencyScore(int? days, {required bool hasActualCrmActivity}) {
    if (days == null) return 10;
    if (!hasActualCrmActivity) {
      return _registrationFreshnessScore(days, 'active').clamp(0, 55);
    }
    if (days <= 7) return 100;
    if (days <= 30) return 80;
    if (days <= 60) return 60;
    if (days <= 90) return 45;
    if (days <= 180) return 25;
    return 10;
  }

  double _registrationFreshnessScore(int? days, String statusName) {
    final statusPenalty = statusName == 'blocked' || statusName == 'inactive'
        ? 20
        : 0;
    final base = switch (days) {
      null => 15,
      <= 30 => 70,
      <= 90 => 55,
      <= 180 => 35,
      _ => 15,
    };
    return (base - statusPenalty).clamp(0, 100).toDouble();
  }

  double _crmFrequencyScore(int count) {
    if (count <= 0) return 10;
    if (count == 1) return 45;
    if (count <= 3) return 65;
    return 85;
  }

  double _purchaseFrequencyScore(int? count, DateTime? lastPurchaseAt) {
    if (count == null) return lastPurchaseAt == null ? 0 : 35;
    if (count <= 0) return 0;
    return (count.clamp(0, 6) / 6) * 100;
  }

  double _revenueScore(double? revenue, {required String? fallbackPotential}) {
    if (revenue != null) {
      if (revenue <= 0) return 0;
      return ((revenue / 50000) * 100).clamp(0, 100).toDouble();
    }
    final potential = fallbackPotential?.trim().toLowerCase();
    return switch (potential) {
      'alto' || 'high' || 'a' || 'tier-a' => 70,
      'medio' || 'medium' || 'b' || 'tier-b' => 50,
      'baixo' || 'low' || 'c' || 'tier-c' => 30,
      _ => 25,
    };
  }

  double _revenueTrendScore({
    required double? current,
    required double? previous,
  }) {
    if (current == null || previous == null || previous <= 0) return 50;
    final dropRatio = (previous - current) / previous;
    if (dropRatio <= 0) return 100;
    if (dropRatio <= 0.20) return 70;
    if (dropRatio <= 0.50) return 40;
    return 15;
  }

  double _followUpHygieneScore(int overdueFollowUps) {
    if (overdueFollowUps <= 0) return 100;
    if (overdueFollowUps == 1) return 70;
    if (overdueFollowUps == 2) return 45;
    return 10;
  }

  int _weightedScore(List<_WeightedScore> scores) {
    final total = scores.fold<double>(
      0,
      (sum, item) => sum + (item.score.clamp(0, 100) * item.weight),
    );
    return total.round().clamp(0, 100);
  }
}

final class CustomerScoringInput {
  const CustomerScoringInput({
    required this.customer,
    required this.now,
    this.crmActivities = const <CustomerScoringActivitySignal>[],
    this.purchaseCountLast12Months,
    this.revenueLast12Months,
    this.currentPeriodRevenue,
    this.previousPeriodRevenue,
    this.overdueFollowUps = 0,
  });

  final Customer customer;
  final DateTime now;
  final List<CustomerScoringActivitySignal> crmActivities;
  final int? purchaseCountLast12Months;
  final double? revenueLast12Months;
  final double? currentPeriodRevenue;
  final double? previousPeriodRevenue;
  final int overdueFollowUps;
}

final class CustomerScoringActivitySignal {
  const CustomerScoringActivitySignal({
    required this.organizationId,
    required this.customerId,
    required this.occurredAt,
  });

  final String organizationId;
  final String customerId;
  final DateTime occurredAt;
}

final class CustomerScoringResult {
  const CustomerScoringResult({
    required this.commercialScore,
    required this.healthScore,
    required this.healthScoreBand,
    required this.scoreUpdatedAt,
    required this.scoreFormulaVersion,
    required this.scoreDataCoverage,
  });

  final int commercialScore;
  final int healthScore;
  final CustomerHealthScoreBand healthScoreBand;
  final DateTime scoreUpdatedAt;
  final String scoreFormulaVersion;
  final CustomerScoreDataCoverage scoreDataCoverage;
}

final class _WeightedScore {
  const _WeightedScore(this.score, this.weight);

  final double score;
  final double weight;
}
