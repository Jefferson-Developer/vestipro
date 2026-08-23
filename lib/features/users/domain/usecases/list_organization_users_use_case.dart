import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../../organizations/domain/entities/membership.dart';
import '../../../organizations/domain/entities/team.dart';
import '../../../organizations/domain/repositories/membership_repository.dart';
import '../../../organizations/domain/repositories/team_repository.dart';
import '../entities/organization_user.dart';

/// Builds the administrative user roster of one Organization (`UserListPage`,
/// TASK-042): every non-deleted [Membership], joined with the names of the
/// [Team]s it belongs to.
///
/// Deliberately composes [MembershipRepository]/[TeamRepository] instead of
/// a dedicated data source — both already expose exactly what this needs
/// ([MembershipRepository.listByOrganization]/
/// [TeamRepository.listByOrganization]), and this feature has no Firestore
/// document of its own to read. Same precedent as `InviteFormBloc`
/// (`lib/features/invites/presentation/bloc/invite_form_bloc.dart`), which
/// also depends directly on `organizations`' repositories.
///
/// Both repository reads are already tenant-scoped by [organizationId] —
/// `firestore.rules` remains the real source of truth (TASK-030/TASK-042: a
/// bulk `members` `list` query requires `user.changeRole`).
@injectable
final class ListOrganizationUsersUseCase {
  const ListOrganizationUsersUseCase(
    this._membershipRepository,
    this._teamRepository,
  );

  final MembershipRepository _membershipRepository;
  final TeamRepository _teamRepository;

  Future<AppResult<List<OrganizationUser>>> call(String organizationId) async {
    final membershipsResult = await _membershipRepository.listByOrganization(
      organizationId,
    );
    if (membershipsResult is AppFailure<List<Membership>>) {
      return AppFailure<List<OrganizationUser>>(membershipsResult.failure);
    }
    final memberships =
        (membershipsResult as AppSuccess<List<Membership>>).value;

    // A Team lookup failure (e.g. offline) never blocks the roster itself —
    // it only means every `teamNames` comes back empty, which
    // `UserListPage` already renders gracefully (an empty "Equipe" cell is
    // far less harmful than hiding the whole list of users).
    final teamsResult = await _teamRepository.listByOrganization(
      organizationId,
    );
    final teamNameById = teamsResult.fold(
      onSuccess: (teams) => <String, String>{
        for (final team in teams) team.id: team.name,
      },
      onFailure: (_) => const <String, String>{},
    );

    final users =
        memberships.map((membership) {
          final trimmedName = membership.name?.trim();
          return OrganizationUser(
            userId: membership.userId,
            name: (trimmedName != null && trimmedName.isNotEmpty)
                ? trimmedName
                : membership.userId,
            email: membership.email?.trim() ?? '',
            roleName: membership.roleName,
            status: membership.status,
            teamIds: membership.teamIds,
            teamNames: membership.teamIds
                .map((teamId) => teamNameById[teamId])
                .whereType<String>()
                .toList(growable: false),
          );
        }).toList()..sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );

    return AppSuccess<List<OrganizationUser>>(users);
  }
}
