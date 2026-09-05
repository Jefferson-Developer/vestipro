/// Everything a push notification's `data` payload may carry (TASK-150) —
/// deliberately excludes any personal/sensitive field: only identifiers and
/// references a screen can use to fetch the real content after the user
/// opens the app, never the content itself (see `PushNotificationRouter`'s
/// own docs and TASK-150's "payload never contains personal data" rule).
///
/// Built by `PushNotificationRouter` from a raw `RemoteMessage`, so nothing
/// outside `lib/core/notifications/push/` ever depends on
/// `firebase_messaging`'s own `RemoteMessage` type — consumed starting
/// TASK-151 (central de notificações) to actually navigate to [deepLink].
final class PushNotificationPayload {
  const PushNotificationPayload({
    required this.messageId,
    required this.organizationId,
    required this.deepLink,
    required this.category,
    required this.data,
  });

  final String? messageId;
  final String? organizationId;
  final String? deepLink;
  final String? category;

  /// The raw `data` map (already stringified), for a future consumer that
  /// needs a field this type does not name explicitly yet.
  final Map<String, String> data;
}
