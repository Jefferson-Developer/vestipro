/// Data-layer representation of a `firebase_auth` user, isolating the SDK
/// type from the rest of `lib/core/auth/data/`.
final class AuthUserDto {
  const AuthUserDto({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.emailVerified,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final bool emailVerified;
}
