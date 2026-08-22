import 'dart:developer' as developer;

import 'package:firebase_performance/firebase_performance.dart';

import '../environment/app_environment.dart';

/// Toggles Performance Monitoring collection based on [environment] — the
/// Performance Monitoring counterpart of `configureCrashlytics` (TASK-016)
/// and `configureAnalytics` (TASK-017). There is no local Performance
/// Monitoring emulator, and (per ADR-0002, TASK-010) VestiPro uses a single
/// real Firebase project for every flavor.
///
/// Decision (TASK-019): collection stays disabled for `development`, so a
/// developer's local run (including every custom trace, e.g. the debug
/// build's own dependency-injection-setup trace) never pollutes the real
/// Firebase Performance console — same reasoning as Crashlytics/Analytics.
/// `staging` and `production` both collect normally.
///
/// Unlike `configureCrashlytics`/`configureAnalytics` (fire-and-forget via
/// `unawaited`), this function is `async` and fully guarded end-to-end
/// (never completes with an error) so it is also safe to `await` directly
/// from a call site that needs collection already toggled before starting a
/// trace (see `bootstrap.dart`), not only from the lazy DI provider in
/// `lib/app/injection_module.dart` (which still calls it via `unawaited`,
/// exactly like `configureRemoteConfig`, TASK-018).
Future<void> configurePerformance(
  FirebasePerformance performance, {
  required AppEnvironment environment,
}) async {
  try {
    await performance.setPerformanceCollectionEnabled(
      environment.name != AppEnvironmentName.development,
    );
  } catch (error, stackTrace) {
    developer.log(
      'configurePerformance failed to toggle collection; Performance '
      'Monitoring keeps whatever the SDK/platform default currently is.',
      name: 'vestipro.performance_monitor',
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
