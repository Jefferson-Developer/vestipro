import '../../../../core/utils/utils.dart';
import '../entities/user_profile.dart';

/// Persists the basic user profile created during sign-up (TASK-035),
/// decoupled from [AuthRepository]: this repository only ever talks to the
/// `users/{uid}` Firestore document (see `firestore.rules`), never
/// `firebase_auth` — that boundary already belongs to `AuthRepository`.
abstract interface class UserProfileRepository {
  /// Creates (or overwrites with the same, idempotent shape) the profile
  /// document for [profile.uid]. Safe to retry: a caller that already
  /// created the Firebase Auth account but failed on this step can call it
  /// again with the exact same [profile] without causing a conflict, since
  /// the write is a `set`, not a `create`-only operation.
  Future<AppResult<void>> createInitialProfile(UserProfile profile);
}
