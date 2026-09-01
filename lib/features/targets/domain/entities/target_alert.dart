import 'target_alert_assessment.dart';

/// Actionable alert rendered in the dashboard and optionally queued as an
/// internal notification.
final class TargetAlert {
  const TargetAlert({
    required this.classification,
    required this.title,
    required this.message,
    required this.deepLink,
    required this.daysRemaining,
    required this.paceRatio,
    required this.notificationQueued,
  });

  final TargetAlertClassification classification;
  final String title;
  final String message;
  final String deepLink;
  final int daysRemaining;
  final double paceRatio;
  final bool notificationQueued;
}
