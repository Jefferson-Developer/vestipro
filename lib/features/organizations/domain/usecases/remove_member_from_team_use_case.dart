import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/membership.dart';
import '../entities/team.dart';
import '../repositories/membership_repository.dart';
import '../repositories/team_repository.dart';
import 'team_membership_policy.dart';

@injectable
final class RemoveMemberFromTeamUseCase {
  const RemoveMemberFromTeamUseCase(
    this._teamRepository,
    this._membershipRepository,
  );

  final TeamRepository _teamRepository;
  final MembershipRepository _membershipRepository;

  Future<AppResult<Team>> call({
    required String organizationId,
    required String id,
    required String userId,
    required String updatedBy,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedId = id.trim();
    final trimmedUserId = userId.trim();
    final trimmedUpdatedBy = updatedBy.trim();

    final fieldErrors = <String, String>{};
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedUserId.isEmpty) fieldErrors['userId'] = 'UserId is required.';
    if (trimmedUpdatedBy.isEmpty) {
      fieldErrors['updatedBy'] = 'UpdatedBy is required.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<Team>(
        ValidationFailure(
          'Invalid remove-member-from-team payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_remove_member_from_team_payload',
        ),
      );
    }

    final membershipResult = await _membershipRepository.getByUser(
      organizationId: trimmedOrganizationId,
      userId: trimmedUserId,
    );
    if (membershipResult case AppFailure<Membership>(failure: final failure)) {
      return AppFailure<Team>(failure);
    }
    final membership = (membershipResult as AppSuccess<Membership>).value;

    final updatedTeamResult = await _teamRepository.removeMember(
      organizationId: trimmedOrganizationId,
      id: trimmedId,
      userId: trimmedUserId,
      updatedBy: trimmedUpdatedBy,
    );
    if (updatedTeamResult case AppFailure<Team>()) {
      return updatedTeamResult;
    }

    final nextTeamIds = normalizeTeamMemberIds(
      membership.teamIds.where((teamId) => teamId != trimmedId),
    );
    final updateMembershipResult = await _membershipRepository.update(
      organizationId: trimmedOrganizationId,
      userId: trimmedUserId,
      roleId: membership.roleId,
      roleName: membership.roleName,
      teamIds: nextTeamIds,
      status: membership.status,
      updatedBy: trimmedUpdatedBy,
    );
    if (updateMembershipResult case AppFailure<Membership>(
      failure: final failure,
    )) {
      return AppFailure<Team>(failure);
    }

    return updatedTeamResult;
  }
}
