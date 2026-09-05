/// Owns the whole FCM token lifecycle for the current device (TASK-150):
/// registration at login, renewal when the SDK rotates the token, and
/// removal at logout. No feature is allowed to call
/// `FirebaseMessaging.instance.getToken()`/`deleteToken()` directly.
///
/// Both methods are best-effort by contract: a failure here must never
/// surface as a login/session-restore/logout failure anywhere else in the
/// app (`bootstrap.dart`'s `configurePushNotificationLifecycle` calls these
/// unawaited/without letting a failure propagate, and every implementation
/// must guarantee it never throws).
abstract interface class PushTokenService {
  /// Registers (or refreshes) this device's FCM token for [organizationId]/
  /// [userId]. Called for every session change to a signed-in user — a real
  /// login, or an already-signed-in session restored on a fresh app launch
  /// — and again whenever the underlying FCM token itself rotates.
  Future<void> registerDevice({
    required String organizationId,
    required String userId,
  });

  /// Invalidates whatever [PushDevice] this device most recently registered
  /// and asks the SDK to drop the local FCM token, so a different user
  /// signing in on this same device afterwards starts from a brand-new
  /// token — no lingering registration can ever deliver a push meant for
  /// the account that just signed out.
  Future<void> unregisterCurrentDevice();
}
