import 'push_permission_status.dart';

/// Central abstraction over the OS-level push notification permission
/// (TASK-150). No feature is allowed to call
/// `FirebaseMessaging.instance.requestPermission()` directly — every
/// request goes through this interface, so the actual *moment* the prompt
/// is shown stays a deliberate, contextual decision made by whichever
/// screen calls [requestIfNotAlreadyAsked] (never automatically at app
/// splash — see `AGENTS.md`/TASK-150's own acceptance criteria), while the
/// "never nag a user who already said no" rule lives in exactly one place.
abstract interface class PushPermissionService {
  /// Reads the current OS permission status without prompting anything.
  Future<PushPermissionStatus> currentStatus();

  /// Requests the OS notification permission unless this device has
  /// already asked before (tracked locally, independent of the OS's own
  /// answer) — the prompt is never repeated just because a caller invokes
  /// this again, respecting an earlier refusal instead of nagging the user.
  /// Callers still decide *when* it is contextually appropriate to call
  /// this in the first place; this service only prevents it from being
  /// asked twice.
  Future<PushPermissionStatus> requestIfNotAlreadyAsked();
}
