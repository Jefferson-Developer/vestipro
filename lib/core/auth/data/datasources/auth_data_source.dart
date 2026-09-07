import '../dtos/auth_user_dto.dart';

/// Data-layer contract for authentication SDKs. Implementations translate
/// SDK-specific exceptions into [AppException]s — no `firebase_auth` type
/// may leak past this boundary.
abstract interface class AuthDataSource {
  Stream<AuthUserDto?> get authStateChanges;

  AuthUserDto? get currentUser;

  Future<AuthUserDto> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<AuthUserDto> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  });

  /// Signs in against a federated SAML/OIDC provider (TASK-173) —
  /// [providerId] is `SsoConnectionDoc.providerId`
  /// (`saml.<connectionId>`/`oidc.<connectionId>`), resolved at runtime by
  /// `resolveSsoForEmail`. [isSaml] picks which `AuthProvider` subtype to
  /// build (`SAMLAuthProvider`/`OAuthProvider`) — both are driven through
  /// `FirebaseAuth.signInWithProvider`, which works uniformly across
  /// Web/Android/iOS in this SDK version, no per-platform branching needed.
  Future<AuthUserDto> signInWithFederatedProvider({
    required String providerId,
    required bool isSaml,
  });

  Future<void> signOut();

  Future<void> sendPasswordResetEmail({required String email});

  /// Forces a refresh of the current user's ID token against Firebase Auth
  /// (TASK-041), so a remotely revoked/disabled account or an invalidated
  /// refresh token is detected instead of silently trusting a locally
  /// cached, no-longer-valid session. A no-op when there is no signed-in
  /// user.
  Future<void> refreshIdToken();
}
