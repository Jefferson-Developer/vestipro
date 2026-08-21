import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_user.freezed.dart';

/// The signed-in user for the current session, as seen by the rest of the
/// app — never exposes any `firebase_auth` type outside `lib/core/auth/data/`.
@freezed
abstract class SessionUser with _$SessionUser {
  const factory SessionUser({
    required String uid,
    String? email,
    String? displayName,
    required bool emailVerified,
  }) = _SessionUser;
}
