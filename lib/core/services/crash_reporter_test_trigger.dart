import 'package:flutter/foundation.dart' show kDebugMode;

/// Throws a distinctive, easily-recognizable error so a developer can
/// confirm — in a debug/dev build only — that `FlutterError.onError` really
/// forwards uncaught errors to [CrashReporter] and, from there, to the
/// Firebase Crashlytics console (TASK-016).
///
/// A no-op outside [kDebugMode]: never call this from a path reachable in a
/// staging/production build.
void triggerCrashlyticsTestCrash() {
  if (!kDebugMode) return;

  throw StateError(
    'Crash de teste do VestiPro (TASK-016) — confirme no console do '
    'Firebase Crashlytics do ambiente de desenvolvimento.',
  );
}
