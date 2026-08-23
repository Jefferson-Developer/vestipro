import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';

/// The basic profile created for a brand-new user during sign-up
/// (TASK-035), before any Organization exists for them (TASK-037's
/// exclusive responsibility — see `SignUpPage`).
///
/// [termsVersion]/[termsAcceptedAt] are the LGPD consent record for the
/// Terms of Service/Privacy Policy acceptance checkbox on the sign-up form:
/// kept on the profile itself (never overwritten) so there is always
/// evidence of *which* version of the terms a user agreed to and *when* —
/// required for future consent audits (EPIC-20).
@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String uid,
    required String name,
    required String email,
    required DateTime createdAt,
    required String termsVersion,
    required DateTime termsAcceptedAt,
  }) = _UserProfile;
}
