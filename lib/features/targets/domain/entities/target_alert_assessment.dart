enum TargetAlertClassification { highRisk, moderateRisk, onTrack, opportunity }

/// Pure outcome of the alert evaluator before any notification side effect.
final class TargetAlertAssessment {
  const TargetAlertAssessment({
    required this.classification,
    required this.paceRatio,
    required this.daysRemaining,
    required this.achievementPercentage,
    required this.projectedAchievementPercentage,
  });

  final TargetAlertClassification classification;
  final double paceRatio;
  final int daysRemaining;
  final double achievementPercentage;
  final double projectedAchievementPercentage;
}
