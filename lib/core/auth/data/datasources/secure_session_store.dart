/// Persists the minimal session metadata VestiPro is allowed to keep on
/// disk between app restarts.
///
/// Firebase Auth's own SDK already persists the real session (refresh
/// token) natively — this store never duplicates that. It only remembers
/// which user last signed in, so [SessionService] has something concrete
/// to prove it clears on logout. Never a token, never a password: any
/// value written here must stay safe to read back from a crash report.
abstract interface class SecureSessionStore {
  /// Records [uid] as the last signed-in user. Called by [SessionService]
  /// whenever `AuthRepository.authStateChanges` emits a signed-in user.
  Future<void> persistSignedInUserId(String uid);

  /// The last signed-in user id persisted by [persistSignedInUserId], or
  /// `null` when nothing was ever stored or it was cleared.
  Future<String?> readSignedInUserId();

  /// Wipes every value this store holds. Called on logout and whenever a
  /// session is detected as revoked, so no trace of the previous user is
  /// left on the device.
  Future<void> clear();
}
