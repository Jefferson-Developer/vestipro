import '../../../organizations/domain/value_objects/system_role_name.dart';

/// Result returned after a successful `updateUserRole` callable execution
/// (TASK-043). Contains only technical ids and role codes: names/e-mails stay
/// out of analytics and are already available on the visible roster row.
final class UserRoleUpdateResult {
  const UserRoleUpdateResult({
    required this.organizationId,
    required this.targetUserId,
    required this.previousRoleName,
    required this.roleName,
    required this.updatedAt,
  });

  final String organizationId;
  final String targetUserId;
  final SystemRoleName previousRoleName;
  final SystemRoleName roleName;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) {
    return other is UserRoleUpdateResult &&
        other.organizationId == organizationId &&
        other.targetUserId == targetUserId &&
        other.previousRoleName == previousRoleName &&
        other.roleName == roleName &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
    organizationId,
    targetUserId,
    previousRoleName,
    roleName,
    updatedAt,
  );
}
