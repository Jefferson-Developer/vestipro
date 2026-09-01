/// Organization-configurable thresholds for proactive target alerts.
final class TargetAlertSettings {
  const TargetAlertSettings({
    this.highRiskPaceRatioThreshold = 0.75,
    this.moderateRiskPaceRatioThreshold = 0.95,
    this.opportunityAchievementThreshold = 90,
    this.opportunityDaysRemainingThreshold = 5,
    this.notificationCooldown = const Duration(hours: 24),
  }) : assert(highRiskPaceRatioThreshold > 0),
       assert(moderateRiskPaceRatioThreshold > highRiskPaceRatioThreshold),
       assert(opportunityAchievementThreshold >= 0),
       assert(opportunityDaysRemainingThreshold >= 0);

  final double highRiskPaceRatioThreshold;
  final double moderateRiskPaceRatioThreshold;
  final double opportunityAchievementThreshold;
  final int opportunityDaysRemainingThreshold;
  final Duration notificationCooldown;
}
