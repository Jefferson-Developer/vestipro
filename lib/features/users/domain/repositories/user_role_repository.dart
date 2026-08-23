import '../../../../core/utils/utils.dart';
import '../../../organizations/domain/value_objects/system_role_name.dart';
import '../entities/user_role_update_result.dart';

/// Contract for administrative user-role changes (TASK-043).
///
/// Implementations must go through the `updateUserRole` callable. The client
/// can narrow choices for UX, but the real authorization, last-OWNER guard
/// and audit log are all server-side responsibilities.
abstract interface class UserRoleRepository {
  Future<AppResult<UserRoleUpdateResult>> updateUserRole({
    required String organizationId,
    required String targetUserId,
    required SystemRoleName roleName,
  });
}
