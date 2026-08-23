import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/membership.dart';
import '../entities/team.dart';
import '../repositories/membership_repository.dart';
import '../repositories/organization_repository.dart';
import '../repositories/team_repository.dart';
import 'team_membership_policy.dart';

@injectable
final class AddMemberToTeamUseCase {
  const AddMemberToTeamUseCase(
    this._teamRepository,
    this._membershipRepository,
    this._organizationRepository,
  );

  final TeamRepository _teamRepository;
  final MembershipRepository _membershipRepository;
  final OrganizationRepository _organizationRepository;

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
          'Invalid add-member-to-team payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_add_member_to_team_payload',
        ),
      );
    }

    final teamResult = await _teamRepository.getById(
      organizationId: trimmedOrganizationId,
      id: trimmedId,
    );
    if (teamResult case AppFailure<Team>(failure: final failure)) {
      return AppFailure<Team>(failure);
    }
    final team = (teamResult as AppSuccess<Team>).value;

    final membershipResult = await _membershipRepository.getByUser(
      organizationId: trimmedOrganizationId,
      userId: trimmedUserId,
    );
    if (membershipResult case AppFailure<Membership>(failure: final failure)) {
      return AppFailure<Team>(failure);
    }
    final membership = (membershipResult as AppSuccess<Membership>).value;
    if (!isTeamMember(membership)) {
      return AppFailure<Team>(invalidTeamMemberFailure(trimmedUserId));
    }

    final maxTeamsResult = await _maxTeamsPerUser(trimmedOrganizationId);
    if (maxTeamsResult case AppFailure<int?>(failure: final failure)) {
      return AppFailure<Team>(failure);
    }
    final maxTeamsPerUser = (maxTeamsResult as AppSuccess<int?>).value;
    if (maxTeamsPerUser != null &&
        !membership.teamIds.contains(trimmedId) &&
        membership.teamIds.length >= maxTeamsPerUser) {
      return AppFailure<Team>(
        teamLimitReachedFailure(
          userId: trimmedUserId,
          maxTeamsPerUser: maxTeamsPerUser,
        ),
      );
    }

    final updatedTeamResult = team.memberIds.contains(trimmedUserId)
        ? AppSuccess<Team>(team)
        : await _teamRepository.addMember(
            organizationId: trimmedOrganizationId,
            id: trimmedId,
            userId: trimmedUserId,
            updatedBy: trimmedUpdatedBy,
          );
    if (updatedTeamResult case AppFailure<Team>()) {
      return updatedTeamResult;
    }

    final nextTeamIds = normalizeTeamMemberIds(<String>[
      ...membership.teamIds,
      trimmedId,
    ]);
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

  Future<AppResult<int?>> _maxTeamsPerUser(String organizationId) async {
    final organizationResult = await _organizationRepository.getById(
      organizationId,
    );
    return organizationResult.fold(
      onSuccess: (organization) =>
          AppSuccess<int?>(organization.settings.maxTeamsPerUser),
      onFailure: (failure) => AppFailure<int?>(failure),
    );
  }
}
