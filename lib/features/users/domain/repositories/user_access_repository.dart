import '../../../../core/utils/utils.dart';
import '../entities/user_access_update_result.dart';

/// Contract for administrative activation/deactivation of organization users
/// (TASK-046).
///
/// Implementations must go through the `deactivateUser`/`reactivateUser`
/// callables. The client can ask for confirmation and update its local
/// roster after success, but the real authorization, last-OWNER guard,
/// token revocation and audit log are all server-side responsibilities.
abstract interface class UserAccessRepository {
  Future<AppResult<UserAccessUpdateResult>> deactivateUser({
    required String organizationId,
    required String targetUserId,
  });

  Future<AppResult<UserAccessUpdateResult>> reactivateUser({
    required String organizationId,
    required String targetUserId,
  });
}
