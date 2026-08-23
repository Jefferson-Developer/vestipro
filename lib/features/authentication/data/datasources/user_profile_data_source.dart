import '../dtos/user_profile_dto.dart';

/// Data access contract for the root `users/{uid}` document (TASK-035).
/// [FirestoreUserProfileDataSource] is the only implementation today.
abstract interface class UserProfileDataSource {
  /// Writes the profile document at `users/{dto.uid}`, overwriting it with
  /// the exact same shape on a retry (idempotent `set`, never a
  /// `create`-only operation — see [UserProfileRepository.createInitialProfile]).
  Future<void> createInitialProfile(UserProfileDto dto);
}
