import '../../organizations/domain/value_objects/system_role_name.dart';

/// Relative power of each of the 7 built-in [SystemRoleName] roles, mirrored
/// from `functions/src/invites/invite-shared.ts`'s `SYSTEM_ROLE_RANK` (kept
/// in sync manually — same trade-off already accepted for
/// `firestore.rules`' `roleHasCapability` vs.
/// `lib/core/permissions/role_permission_matrix.dart`). Rank `0` is the most
/// powerful ([SystemRoleName.owner]); higher numbers are strictly less
/// powerful.
///
/// Used only for the client-side UX of narrowing `InviteUserPage`'s role
/// dropdown to roles the signed-in user is actually allowed to assign — the
/// real enforcement of "an ADMIN cannot invite an OWNER" happens
/// server-side, independently, inside the `createInvite`/`resendInvite`
/// Cloud Functions (`assertCanIssueInvite`).
const Map<SystemRoleName, int> systemRoleRank = <SystemRoleName, int>{
  SystemRoleName.owner: 0,
  SystemRoleName.admin: 1,
  SystemRoleName.salesManager: 2,
  SystemRoleName.salesRep: 3,
  SystemRoleName.salesAssistant: 4,
  SystemRoleName.finance: 5,
  SystemRoleName.readOnly: 6,
};

/// Every [SystemRoleName] a caller whose own role is [callerRole] is allowed
/// to invite someone into (no more powerful than [callerRole] itself) —
/// e.g. [SystemRoleName.admin] may assign anything except
/// [SystemRoleName.owner]; [SystemRoleName.owner] may assign any role.
///
/// A role name that does not parse into a [SystemRoleName] (custom roles,
/// not modeled by invites yet) has no defined rank and is treated as
/// granted nothing — same default-deny precedent as
/// `RolePermissionMatrix.capabilitiesForRoleName`.
List<SystemRoleName> assignableRolesFor(SystemRoleName callerRole) {
  final callerRank = systemRoleRank[callerRole]!;
  return SystemRoleName.values
      .where((role) => systemRoleRank[role]! >= callerRank)
      .toList(growable: false);
}

/// Parses a raw `Membership.roleName`/`Role.name` string (e.g. `'OWNER'`)
/// back into a [SystemRoleName], or `null` when it does not match any of
/// the 7 built-in roles (a custom role, or an unexpected value) — callers
/// decide how to handle that instead of this silently defaulting to any
/// particular role.
SystemRoleName? systemRoleNameFromCode(String code) {
  for (final role in SystemRoleName.values) {
    if (role.code == code) return role;
  }
  return null;
}
