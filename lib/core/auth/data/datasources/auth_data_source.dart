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

  Future<void> signOut();

  Future<void> sendPasswordResetEmail({required String email});
}
