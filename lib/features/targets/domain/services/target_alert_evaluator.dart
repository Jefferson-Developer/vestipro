import '../entities/target.dart';
import '../entities/target_alert_assessment.dart';
import '../entities/target_progress_view_model.dart';
import '../value_objects/target_alert_settings.dart';

/// Compares the current pace against the pace required to hit the target.
final class TargetAlertEvaluator {
  const TargetAlertEvaluator();

  TargetAlertAssessment evaluate({
    required Target target,
    required TargetProgressViewModel progress,
    required TargetAlertSettings settings,
    required DateTime now,
  }) {
    if (progress.isPeriodNotStarted || progress.isPeriodEnded) {
      return TargetAlertAssessment(
        classification: TargetAlertClassification.onTrack,
        paceRatio: 1,
        daysRemaining: 0,
        achievementPercentage: progress.achievementPercentage,
        projectedAchievementPercentage: progress.projectedAchievementPercentage,
      );
    }

    final elapsed = progress.elapsedTimePercentage;
    final paceRatio = elapsed <= 0
        ? 1.0
        : progress.achievementPercentage / elapsed;
    final daysRemaining = target.endDate
        .difference(now)
        .inDays
        .clamp(0, 365000);

    final classification =
        progress.achievementPercentage >=
                settings.opportunityAchievementThreshold &&
            daysRemaining <= settings.opportunityDaysRemainingThreshold
        ? TargetAlertClassification.opportunity
        : paceRatio < settings.highRiskPaceRatioThreshold
        ? TargetAlertClassification.highRisk
        : paceRatio < settings.moderateRiskPaceRatioThreshold
        ? TargetAlertClassification.moderateRisk
        : TargetAlertClassification.onTrack;

    return TargetAlertAssessment(
      classification: classification,
      paceRatio: paceRatio,
      daysRemaining: daysRemaining,
      achievementPercentage: progress.achievementPercentage,
      projectedAchievementPercentage: progress.projectedAchievementPercentage,
    );
  }
}
