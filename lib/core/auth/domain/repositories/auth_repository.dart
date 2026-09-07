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

  /// Signs in against a federated SAML/OIDC provider registered with
  /// Identity Platform for a specific organization's corporate SSO
  /// connection (TASK-173) — [providerId] is the exact
  /// `SsoConnectionDoc.providerId` `resolveSsoForEmail` resolved at runtime
  /// (`saml.<connectionId>`/`oidc.<connectionId>`), never a hardcoded value.
  ///
  /// Deliberately a separate method from [signInWithProvider] (which only
  /// ever covers a fixed, compile-time-known [AuthProviderType] such as
  /// Google/Apple): a corporate SSO connection's `providerId` is dynamic,
  /// resolved per organization at runtime, so it cannot be expressed as an
  /// enum value. Only ever authenticates the caller with Firebase Auth —
  /// completing the just-in-time provisioning/RBAC decision is always
  /// `completeSsoLogin`'s (a separate, subsequent Cloud Function call), same
  /// "authentication vs. authorization are different concerns" boundary
  /// this repository already keeps for `signInWithEmailAndPassword`.
  Future<AppResult<SessionUser>> signInWithFederatedProvider({
    required String providerId,
    required bool isSaml,
  });

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
