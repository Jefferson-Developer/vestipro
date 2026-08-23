import '../../../organizations/domain/value_objects/membership_status.dart';

/// Result returned after a successful `deactivateUser`/`reactivateUser`
/// callable execution (TASK-046). Contains no PII: the visible roster row
/// already carries name/e-mail when the UI needs them.
final class UserAccessUpdateResult {
  const UserAccessUpdateResult({
    required this.organizationId,
    required this.targetUserId,
    required this.previousStatus,
    required this.status,
    required this.updatedAt,
  });

  final String organizationId;
  final String targetUserId;
  final MembershipStatus previousStatus;
  final MembershipStatus status;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) {
    return other is UserAccessUpdateResult &&
        other.organizationId == organizationId &&
        other.targetUserId == targetUserId &&
        other.previousStatus == previousStatus &&
        other.status == status &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
    organizationId,
    targetUserId,
    previousStatus,
    status,
    updatedAt,
  );
}
