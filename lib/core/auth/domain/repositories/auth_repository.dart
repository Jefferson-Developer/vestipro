import '../../../utils/utils.dart';
import '../entities/session_user.dart';
import '../value_objects/auth_provider_type.dart';

/// Domain contract for authentication. The only session boundary the rest
/// of the app is allowed to depend on — nothing outside `lib/core/auth/`
/// may import `firebase_auth` directly.
abstract interface class AuthRepository {
  /// Emits the signed-in [SessionUser] whenever the session changes, or
  /// `null` when signed out.
  Stream<SessionUser?> get authStateChanges;

  /// Synchronous snapshot of the current session, or `null` when signed out.
  SessionUser? get currentUser;

  Future<AppResult<SessionUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Creates a brand-new Firebase Auth account and signs it in (TASK-035).
  ///
  /// [displayName] is stored on the Firebase Auth user itself (available on
  /// every subsequent [SessionUser] without a round-trip to Firestore); the
  /// richer profile document (`createdAt`, terms consent) is a separate
  /// concern owned by `UserProfileRepository`, never this repository — this
  /// method only ever talks to Firebase Auth, mirroring the existing
  /// boundary between authentication and the rest of the domain.
  Future<AppResult<SessionUser>> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  });

  /// Extension point for providers that do not need e-mail/password inputs
  /// (Google, Apple, corporate SSO — TASK-173). Returns a [Failure] for any
  /// provider not implemented yet, including [AuthProviderType.emailAndPassword]
  /// itself, which must go through [signInWithEmailAndPassword] instead.
  Future<AppResult<SessionUser>> signInWithProvider(AuthProviderType provider);

  Future<AppResult<void>> signOut();

  Future<AppResult<void>> sendPasswordResetEmail({required String email});

  /// Forces a refresh of the signed-in user's ID token (TASK-041). Returns
  /// an [AuthenticationFailure] carrying the original Firebase code
  /// (`user-disabled`, `user-token-expired`, `invalid-user-token`,
  /// `user-not-found`) when the session is no longer valid — used by
  /// [SessionService.ensureSessionIsActive] to tell a real revocation apart
  /// from a transient connectivity failure. Succeeds as a no-op when there
  /// is no signed-in user.
  Future<AppResult<void>> refreshSession();
}
