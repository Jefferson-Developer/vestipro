import 'dart:async' show unawaited;

import 'package:firebase_analytics/firebase_analytics.dart';

import '../environment/app_environment.dart';
import 'analytics_user_properties.dart';

/// Toggles Analytics collection and tags test/QA traffic based on
/// [environment] — the Analytics counterpart of `configureCrashlytics`
/// (TASK-016). There is no local Analytics emulator, and (per ADR-0002,
/// TASK-010) VestiPro uses a single real Firebase project for every
/// flavor, so `staging` sends events to the very same project as
/// `production`.
///
/// Decision (TASK-017):
/// - `development` never collects at all — a developer's local run must
///   never touch the real Analytics console, same as Crashlytics.
/// - `staging` collects normally (so the event pipeline itself is validated
///   before release) but is tagged with the
///   [AnalyticsUserProperties.isTestAccount] user property, so BI
///   dashboards built on top of this data (TASK-133+) can filter staging
///   traffic out of real commercial metrics.
/// - `production` collects normally and explicitly clears
///   [AnalyticsUserProperties.isTestAccount].
void configureAnalytics(
  FirebaseAnalytics analytics, {
  required AppEnvironment environment,
}) {
  final isDevelopment = environment.name == AppEnvironmentName.development;

  unawaited(analytics.setAnalyticsCollectionEnabled(!isDevelopment));
  unawaited(
    analytics.setUserProperty(
      name: AnalyticsUserProperties.isTestAccount,
      value: environment.isProduction ? null : 'true',
    ),
  );
}
