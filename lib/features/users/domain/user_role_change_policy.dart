import '../../invites/domain/role_hierarchy.dart';
import '../../organizations/domain/value_objects/system_role_name.dart';

/// Returns true when the visible role change deserves an explicit
/// confirmation step before submission. This is UX only: authorization and
/// the last-OWNER invariant are still enforced by the Cloud Function.
bool isSensitiveRoleChange({
  required SystemRoleName currentRole,
  required SystemRoleName nextRole,
}) {
  final demotesOwner =
      currentRole == SystemRoleName.owner && nextRole != SystemRoleName.owner;
  final promotesToAdminOrAbove =
      systemRoleRank[nextRole]! <= systemRoleRank[SystemRoleName.admin]! &&
      systemRoleRank[nextRole]! < systemRoleRank[currentRole]!;

  return demotesOwner || promotesToAdminOrAbove;
}
