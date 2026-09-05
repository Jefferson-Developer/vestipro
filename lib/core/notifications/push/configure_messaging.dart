import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';

/// Configures presentation for a push that arrives while the app is
/// already in the foreground (TASK-150) — the Messaging counterpart of
/// `configureAnalytics`/`configurePerformance`. Without this, iOS/macOS
/// silently drop the OS-level banner/sound for a foreground push (Android/
/// Web are unaffected either way), so a foreground push would otherwise
/// only be observable through `FirebaseMessaging.onMessage`, never as a
/// visible system notification.
///
/// Guarded end-to-end: never completes with an error, matching every other
/// `configureX` function in this codebase — a foreground-presentation
/// misconfiguration must never be the reason Messaging itself fails to
/// resolve.
Future<void> configureMessaging(FirebaseMessaging messaging) async {
  try {
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  } catch (error, stackTrace) {
    developer.log(
      'configureMessaging failed to set foreground presentation options; '
      'Messaging keeps whatever the SDK/platform default currently is.',
      name: 'vestipro.messaging',
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
