import '../../../utils/utils.dart';
import '../entities/session_user.dart';

/// Orchestrates everything about the *current* session that
/// `AuthRepository` alone does not own: persisting the minimal local
/// session footprint, logging out cleanly, and detecting a session that
/// was invalidated remotely (TASK-041).
///
/// `SessionAuthGuard` is the primary caller — it checks
/// [ensureSessionIsActive] on every navigation to a protected route — but
/// any future repository that performs a sensitive authenticated
/// operation may call it too, the same way `PermissionAuthorizationGuard`
/// is not the only place `PermissionService` gets used.
abstract interface class SessionService {
  /// Mirrors `AuthRepository.authStateChanges`.
  Stream<SessionUser?> get sessionChanges;

  /// Mirrors `AuthRepository.currentUser`.
  SessionUser? get currentUser;

  /// Signs the user out and wipes every local trace of the session
  /// (`SecureSessionStore`), synchronously enough that no further
  /// authenticated operation can succeed once this completes — regardless
  /// of whether the remote `signOut()` call itself succeeded.
  Future<AppResult<void>> logout();

  /// Forces a token refresh to detect a session that a server-side action
  /// invalidated since the last check (account disabled/deleted, refresh
  /// token revoked — TASK-046). When that is detected, signs the user out
  /// locally and returns a [Failure] the caller can act on (e.g. redirect
  /// to login with a "session ended" message).
  ///
  /// Never treats a connectivity/unexpected failure as a revocation: an
  /// offline device keeps its session exactly as valid as it already was,
  /// since Firebase Auth's own cached credentials keep working until the
  /// refresh can actually be confirmed against the backend.
  Future<AppResult<void>> ensureSessionIsActive();
}
