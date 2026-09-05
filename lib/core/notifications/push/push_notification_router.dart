import 'push_notification_payload.dart';

/// Prepares deep-link routing for an incoming push (TASK-150) — consumed
/// starting TASK-151 (central de notificações), which is the first feature
/// that actually navigates anywhere from it. This service only observes and
/// normalizes; it never calls `context.go`/`context.push` itself, since it
/// has no `BuildContext` (and must not depend on one to stay resolvable
/// outside a widget tree, e.g. from `bootstrap.dart`).
///
/// Covers every state TASK-150 requires:
/// - Foreground: [messages] emits from `FirebaseMessaging.onMessage`.
/// - Backgrounded, opened by tapping the system notification: [messages]
///   also emits from `FirebaseMessaging.onMessageOpenedApp`.
/// - Terminated, cold-started by tapping the system notification:
///   [consumeInitialMessage].
///
/// A message received while the app process itself is not running at all
/// (fully backgrounded/terminated, not yet tapped) is handled by the
/// separate top-level `firebaseMessagingBackgroundHandler` — this router
/// only ever sees a message once the user has brought the app to the
/// foreground, by design (no `BuildContext`/navigation exists otherwise).
abstract interface class PushNotificationRouter {
  /// Emits every push received while the app process is alive: shown (or
  /// not) in the foreground, or tapped from the system tray while
  /// backgrounded. Never emits the terminated-launch case — see
  /// [consumeInitialMessage] for that.
  Stream<PushNotificationPayload> get messages;

  /// Resolves the push (if any) that cold-started the app from a fully
  /// terminated state. Meant to be consumed exactly once per app launch
  /// (e.g. right after the first authenticated route is reached) — calling
  /// it again returns `null` per the underlying SDK's own contract.
  Future<PushNotificationPayload?> consumeInitialMessage();
}
