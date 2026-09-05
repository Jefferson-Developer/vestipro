import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../../organizations/organizations.dart';
import '../entities/funnel_dashboard_visibility.dart';

@injectable
final class FunnelDashboardVisibilityService {
  const FunnelDashboardVisibilityService(
    this._membershipRepository,
    this._teamRepository,
  );

  final MembershipRepository _membershipRepository;
  final TeamRepository _teamRepository;

  Future<AppResult<FunnelDashboardVisibility>> resolve({
    required String organizationId,
    required String userId,
  }) async {
    final membershipResult = await _membershipRepository.getByUser(
      organizationId: organizationId,
      userId: userId,
    );
    if (membershipResult case AppFailure<Membership>(failure: final failure)) {
      return AppFailure<FunnelDashboardVisibility>(failure);
    }
    final membership = (membershipResult as AppSuccess<Membership>).value;
    if (membership.status != MembershipStatus.active) {
      return const AppSuccess<FunnelDashboardVisibility>(
        FunnelDashboardVisibility(
          mode: FunnelDashboardVisibilityMode.none,
          allowedSellerIds: <String>{},
          allowedTeamIds: <String>{},
        ),
      );
    }
    if (<String>{
      SystemRoleName.owner.code,
      SystemRoleName.admin.code,
      SystemRoleName.finance.code,
    }.contains(membership.roleName)) {
      return const AppSuccess<FunnelDashboardVisibility>(
        FunnelDashboardVisibility(
          mode: FunnelDashboardVisibilityMode.organization,
          allowedSellerIds: <String>{},
          allowedTeamIds: <String>{},
        ),
      );
    }
    if (membership.roleName == SystemRoleName.salesManager.code) {
      final teamsResult = await _teamRepository.listByOrganization(
        organizationId,
      );
      if (teamsResult case AppFailure<List<Team>>(failure: final failure)) {
        return AppFailure<FunnelDashboardVisibility>(failure);
      }
      final teams = (teamsResult as AppSuccess<List<Team>>).value.where(
        (team) =>
            team.managerUserId == userId ||
            membership.teamIds.contains(team.id),
      );
      return AppSuccess<FunnelDashboardVisibility>(
        FunnelDashboardVisibility(
          mode: FunnelDashboardVisibilityMode.team,
          allowedSellerIds: <String>{
            userId,
            for (final team in teams) ...team.memberIds,
          },
          allowedTeamIds: <String>{for (final team in teams) team.id},
        ),
      );
    }
    if (membership.roleName == SystemRoleName.salesRep.code ||
        membership.roleName == SystemRoleName.salesAssistant.code) {
      return AppSuccess<FunnelDashboardVisibility>(
        FunnelDashboardVisibility(
          mode: FunnelDashboardVisibilityMode.own,
          allowedSellerIds: <String>{userId},
          allowedTeamIds: membership.teamIds.toSet(),
        ),
      );
    }
    return const AppSuccess<FunnelDashboardVisibility>(
      FunnelDashboardVisibility(
        mode: FunnelDashboardVisibilityMode.none,
        allowedSellerIds: <String>{},
        allowedTeamIds: <String>{},
      ),
    );
  }
}
