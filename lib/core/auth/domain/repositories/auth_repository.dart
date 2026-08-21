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

  /// Extension point for providers that do not need e-mail/password inputs
  /// (Google, Apple, corporate SSO — TASK-173). Returns a [Failure] for any
  /// provider not implemented yet, including [AuthProviderType.emailAndPassword]
  /// itself, which must go through [signInWithEmailAndPassword] instead.
  Future<AppResult<SessionUser>> signInWithProvider(AuthProviderType provider);

  Future<AppResult<void>> signOut();

  Future<AppResult<void>> sendPasswordResetEmail({required String email});
}
