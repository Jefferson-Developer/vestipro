import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../../organizations/organizations.dart';

/// Enforces the individual-dashboard scope before any seller snapshot is
/// requested. Firestore Rules mirror this decision for defense in depth.
@injectable
final class RepresentativeDashboardVisibilityService {
  const RepresentativeDashboardVisibilityService(
    this._membershipRepository,
    this._teamRepository,
  );

  final MembershipRepository _membershipRepository;
  final TeamRepository _teamRepository;

  Future<AppResult<bool>> canView({
    required String organizationId,
    required String requesterUserId,
    required String sellerId,
  }) async {
    final requesterResult = await _membershipRepository.getByUser(
      organizationId: organizationId,
      userId: requesterUserId,
    );
    if (requesterResult case AppFailure<Membership>(failure: final failure)) {
      return AppFailure<bool>(failure);
    }
    final requester = (requesterResult as AppSuccess<Membership>).value;
    if (requester.status != MembershipStatus.active) {
      return const AppSuccess<bool>(false);
    }
    if (requester.userId == sellerId) {
      return const AppSuccess<bool>(true);
    }
    if (requester.roleName == SystemRoleName.owner.code ||
        requester.roleName == SystemRoleName.admin.code) {
      return const AppSuccess<bool>(true);
    }
    if (requester.roleName != SystemRoleName.salesManager.code) {
      return const AppSuccess<bool>(false);
    }

    final targetResult = await _membershipRepository.getByUser(
      organizationId: organizationId,
      userId: sellerId,
    );
    if (targetResult case AppFailure<Membership>()) {
      return const AppSuccess<bool>(false);
    }
    final target = (targetResult as AppSuccess<Membership>).value;
    if (target.status != MembershipStatus.active) {
      return const AppSuccess<bool>(false);
    }
    final teamsResult = await _teamRepository.listByOrganization(
      organizationId,
    );
    if (teamsResult case AppFailure<List<Team>>(failure: final failure)) {
      return AppFailure<bool>(failure);
    }
    final teams = (teamsResult as AppSuccess<List<Team>>).value;
    final managedTeamIds = <String>{
      ...requester.teamIds,
      for (final team in teams)
        if (team.deletedAt == null && team.managerUserId == requester.userId)
          team.id,
    };
    return AppSuccess<bool>(managedTeamIds.any(target.teamIds.contains));
  }
}
