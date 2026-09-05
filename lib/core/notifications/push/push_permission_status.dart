/// Mirrors `firebase_messaging`'s `AuthorizationStatus` without leaking that
/// Firebase type into anything outside `lib/core/notifications/push/`
/// (`FirebaseMessagingPermissionService` is the only place that converts
/// between the two) — same "Domain sem Firebase" rule every other core
/// service in this codebase follows.
enum PushPermissionStatus {
  /// The user has not been asked yet (or the platform cannot tell).
  notDetermined,

  /// The user explicitly declined — must never be prompted again
  /// automatically (TASK-150 acceptance criteria).
  denied,

  /// The user explicitly allowed notifications.
  authorized,

  /// iOS-only: allowed to deliver quietly (no sound/banner) without an
  /// explicit prompt.
  provisional,
}
