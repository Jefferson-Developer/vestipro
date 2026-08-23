import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../../organizations/organizations.dart';
import '../entities/commercial_team.dart';
import '../entities/organization_user.dart';
import 'list_organization_users_use_case.dart';

@injectable
final class ListCommercialTeamsUseCase {
  const ListCommercialTeamsUseCase(
    this._teamRepository,
    this._listOrganizationUsers,
  );

  final TeamRepository _teamRepository;
  final ListOrganizationUsersUseCase _listOrganizationUsers;

  Future<AppResult<List<CommercialTeam>>> call(String organizationId) async {
    final teamsResult = await _teamRepository.listByOrganization(
      organizationId,
    );
    if (teamsResult case AppFailure<List<Team>>(failure: final failure)) {
      return AppFailure<List<CommercialTeam>>(failure);
    }
    final teams = (teamsResult as AppSuccess<List<Team>>).value;

    final usersResult = await _listOrganizationUsers(organizationId);
    final userById = usersResult.fold(
      onSuccess: (users) => <String, OrganizationUser>{
        for (final user in users) user.userId: user,
      },
      onFailure: (_) => const <String, OrganizationUser>{},
    );

    final commercialTeams =
        teams
            .map(
              (team) => CommercialTeam(
                team: team,
                managerName:
                    userById[team.managerUserId]?.name ??
                    (team.managerUserId.isEmpty
                        ? 'Sem gestor'
                        : team.managerUserId),
                memberNames: team.memberIds
                    .map((memberId) => userById[memberId]?.name ?? memberId)
                    .toList(growable: false),
              ),
            )
            .toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

    return AppSuccess<List<CommercialTeam>>(commercialTeams);
  }
}
