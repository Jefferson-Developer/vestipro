import '../../../../core/errors/errors.dart';
import '../entities/membership.dart';
import '../value_objects/membership_status.dart';
import '../value_objects/system_role_name.dart';

bool isTeamManager(Membership membership) {
  return membership.status == MembershipStatus.active &&
      membership.roleName == SystemRoleName.salesManager.code;
}

bool isTeamMember(Membership membership) {
  return membership.status == MembershipStatus.active &&
      (membership.roleName == SystemRoleName.salesRep.code ||
          membership.roleName == SystemRoleName.salesAssistant.code);
}

List<String> normalizeTeamMemberIds(Iterable<String> memberIds) {
  return <String>{
    for (final memberId in memberIds)
      if (memberId.trim().isNotEmpty) memberId.trim(),
  }.toList(growable: false);
}

ValidationFailure invalidTeamManagerFailure() {
  return const ValidationFailure(
    'Team manager must be an active SALES_MANAGER.',
    fieldErrors: <String, String>{
      'managerUserId': 'Select an active SALES_MANAGER as team manager.',
    },
    code: 'invalid_team_manager',
  );
}

ValidationFailure invalidTeamMemberFailure(String userId) {
  return ValidationFailure(
    'Team members must be active SALES_REP or SALES_ASSISTANT users.',
    fieldErrors: <String, String>{
      'memberIds': 'User $userId cannot be assigned as a team member.',
    },
    code: 'invalid_team_member',
  );
}

ConflictFailure teamLimitReachedFailure({
  required String userId,
  required int maxTeamsPerUser,
}) {
  return ConflictFailure(
    'User $userId already reached the organization team limit.',
    code: 'team_member_limit_reached_$maxTeamsPerUser',
  );
}
