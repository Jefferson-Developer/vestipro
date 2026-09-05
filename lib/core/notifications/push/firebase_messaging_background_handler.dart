import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../firebase_options.dart';

/// Handles a push received while the app process is fully backgrounded or
/// terminated (TASK-150) — registered once via
/// `FirebaseMessaging.onBackgroundMessage` right after
/// `Firebase.initializeApp` in `bootstrap.dart`, exactly as early as
/// FlutterFire's own guidance requires.
///
/// Must be a top-level (or static) function: the platform SDK spawns a
/// separate background isolate to run it, with no access to this app's
/// `bootstrap()` state (TASK-011) — so Firebase is re-initialized here
/// defensively, the same requirement `bootstrap()` itself satisfies for the
/// main isolate.
///
/// Deliberately does nothing beyond a structured log: TASK-150's own
/// payload contract forbids personal/sensitive data in a push (only ids/
/// references), and no `BuildContext`/navigation exists in a background
/// isolate to route a deep link to anyway — that only happens once the app
/// is foregrounded again, through `PushNotificationRouter`
/// (`onMessageOpenedApp`/`getInitialMessage`), consumed starting TASK-151.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  developer.log(
    'Received a push notification while the app was backgrounded/'
    'terminated.',
    name: 'vestipro.messaging',
    level: 800,
  );
}
