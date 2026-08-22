import 'dart:async' show unawaited;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../environment/app_environment.dart';

/// Toggles Crashlytics collection based on [environment] — the Crashlytics
/// counterpart of `configureFirestore` (TASK-013), `configureStorage`
/// (TASK-014) and `configureFunctions` (TASK-015), except there is no local
/// emulator for Crashlytics to connect to.
///
/// Decision (TASK-016): collection stays disabled for `development`, so a
/// developer's local crashes/hot-reload noise never pollutes the
/// production Firebase Crashlytics console. `staging` and `production` both
/// collect normally, since staging is where pre-release regressions must be
/// caught before they reach production.
void configureCrashlytics(
  FirebaseCrashlytics crashlytics, {
  required AppEnvironment environment,
}) {
  unawaited(
    crashlytics.setCrashlyticsCollectionEnabled(
      environment.name != AppEnvironmentName.development,
    ),
  );
}
