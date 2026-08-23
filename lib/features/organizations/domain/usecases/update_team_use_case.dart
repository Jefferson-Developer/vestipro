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
final class UpdateTeamUseCase {
  const UpdateTeamUseCase(
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
    required String name,
    required String managerUserId,
    required List<String> memberIds,
    String? companyId,
    String? branchId,
    required String updatedBy,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedId = id.trim();
    final trimmedName = name.trim();
    final trimmedManagerUserId = managerUserId.trim();
    final normalizedMemberIds = normalizeTeamMemberIds(memberIds);
    final trimmedCompanyId = companyId?.trim();
    final trimmedBranchId = branchId?.trim();
    final trimmedUpdatedBy = updatedBy.trim();

    final fieldErrors = <String, String>{};
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedName.isEmpty) fieldErrors['name'] = 'Name is required.';
    if (trimmedManagerUserId.isEmpty) {
      fieldErrors['managerUserId'] = 'Manager user id is required.';
    }
    if (trimmedUpdatedBy.isEmpty) {
      fieldErrors['updatedBy'] = 'UpdatedBy is required.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<Team>(
        ValidationFailure(
          'Invalid team update payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_team_update_payload',
        ),
      );
    }

    final currentResult = await _teamRepository.getById(
      organizationId: trimmedOrganizationId,
      id: trimmedId,
    );
    if (currentResult case AppFailure<Team>(failure: final failure)) {
      return AppFailure<Team>(failure);
    }
    final current = (currentResult as AppSuccess<Team>).value;

    final managerResult = await _membershipRepository.getByUser(
      organizationId: trimmedOrganizationId,
      userId: trimmedManagerUserId,
    );
    if (managerResult case AppFailure<Membership>(failure: final failure)) {
      return AppFailure<Team>(failure);
    }
    final manager = (managerResult as AppSuccess<Membership>).value;
    if (!isTeamManager(manager)) {
      return AppFailure<Team>(invalidTeamManagerFailure());
    }

    final maxTeamsResult = await _maxTeamsPerUser(trimmedOrganizationId);
    if (maxTeamsResult case AppFailure<int?>(failure: final failure)) {
      return AppFailure<Team>(failure);
    }
    final maxTeamsPerUser = (maxTeamsResult as AppSuccess<int?>).value;

    final membersResult = await _validatedMembers(
      organizationId: trimmedOrganizationId,
      teamId: trimmedId,
      memberIds: normalizedMemberIds,
      maxTeamsPerUser: maxTeamsPerUser,
    );
    if (membersResult case AppFailure<Map<String, Membership>>(
      failure: final failure,
    )) {
      return AppFailure<Team>(failure);
    }
    final memberById =
        (membersResult as AppSuccess<Map<String, Membership>>).value;

    final updatedTeamResult = await _teamRepository.update(
      organizationId: trimmedOrganizationId,
      id: trimmedId,
      name: trimmedName,
      managerUserId: trimmedManagerUserId,
      memberIds: normalizedMemberIds,
      companyId: (trimmedCompanyId == null || trimmedCompanyId.isEmpty)
          ? null
          : trimmedCompanyId,
      branchId: (trimmedBranchId == null || trimmedBranchId.isEmpty)
          ? null
          : trimmedBranchId,
      updatedBy: trimmedUpdatedBy,
    );
    if (updatedTeamResult case AppFailure<Team>()) {
      return updatedTeamResult;
    }

    final currentMemberIds = current.memberIds.toSet();
    final nextMemberIds = normalizedMemberIds.toSet();
    final affectedIds = <String>{
      ...currentMemberIds.difference(nextMemberIds),
      ...nextMemberIds.difference(currentMemberIds),
    };
    for (final memberId in affectedIds) {
      var membership = memberById[memberId];
      if (membership == null) {
        final membershipResult = await _membershipRepository.getByUser(
          organizationId: trimmedOrganizationId,
          userId: memberId,
        );
        if (membershipResult case AppFailure<Membership>(
          failure: final failure,
        )) {
          return AppFailure<Team>(failure);
        }
        membership = (membershipResult as AppSuccess<Membership>).value;
      }
      final nextTeamIds = nextMemberIds.contains(memberId)
          ? normalizeTeamMemberIds(<String>[...membership.teamIds, trimmedId])
          : normalizeTeamMemberIds(
              membership.teamIds.where((teamId) => teamId != trimmedId),
            );
      final updateMembershipResult = await _membershipRepository.update(
        organizationId: trimmedOrganizationId,
        userId: memberId,
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

  Future<AppResult<Map<String, Membership>>> _validatedMembers({
    required String organizationId,
    required String teamId,
    required List<String> memberIds,
    required int? maxTeamsPerUser,
  }) async {
    final memberById = <String, Membership>{};
    for (final memberId in memberIds) {
      final memberResult = await _membershipRepository.getByUser(
        organizationId: organizationId,
        userId: memberId,
      );
      if (memberResult case AppFailure<Membership>(failure: final failure)) {
        return AppFailure<Map<String, Membership>>(failure);
      }
      final member = (memberResult as AppSuccess<Membership>).value;
      if (!isTeamMember(member)) {
        return AppFailure<Map<String, Membership>>(
          invalidTeamMemberFailure(memberId),
        );
      }
      if (maxTeamsPerUser != null &&
          !member.teamIds.contains(teamId) &&
          member.teamIds.length >= maxTeamsPerUser) {
        return AppFailure<Map<String, Membership>>(
          teamLimitReachedFailure(
            userId: memberId,
            maxTeamsPerUser: maxTeamsPerUser,
          ),
        );
      }
      memberById[memberId] = member;
    }
    return AppSuccess<Map<String, Membership>>(memberById);
  }
}
