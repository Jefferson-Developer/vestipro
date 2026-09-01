import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../../organizations/organizations.dart';
import '../../../users/users.dart';
import '../entities/target_visibility_filter.dart';

/// Resolves how much of an organization's `Target` set the signed-in caller
/// may view on the achievement dashboard (TASK-116): every dimension for
/// OWNER/ADMIN, the caller's own dimension plus their teams'/teammates' for
/// a SALES_MANAGER, or only the caller's own `salesRep` dimension for a
/// SALES_REP.
///
/// Reuses [PortfolioVisibilityService] for the exact same
/// OWNER/ADMIN/SALES_MANAGER/SALES_REP role-branching TASK-051 already
/// modeled for Customer visibility instead of re-implementing it —
/// mirroring `OrderVisibilityService`'s own precedent for Order. `Target`
/// has no denormalized `teamId`/`sellerId` the way Customer does (a Target's
/// `dimensionId` may be a user, a team, a company, a collection or a
/// category), so this service additionally resolves the manager's visible
/// [CustomerVisibilityFilter.teamIds] into the concrete set of teammate user
/// ids via [Team.memberIds], exactly like `OrderVisibilityService` does for
/// sellers.
///
/// This resolution is UX/defense-in-depth only: once `Target` gets a
/// Firestore-backed repository, Firestore Security Rules must independently
/// re-verify the same decision, never trusting this service's output as the
/// sole authorization.
@injectable
final class TargetVisibilityService {
  const TargetVisibilityService(
    this._portfolioVisibilityService,
    this._teamRepository,
  );

  final PortfolioVisibilityService _portfolioVisibilityService;
  final TeamRepository _teamRepository;

  Future<AppResult<TargetVisibilityFilter>> resolve({
    required String organizationId,
    required String companyId,
    required String userId,
  }) async {
    final visibilityResult = await _portfolioVisibilityService.resolve(
      organizationId: organizationId,
      companyId: companyId,
      userId: userId,
    );
    if (visibilityResult case AppFailure<CustomerVisibilityFilter>(
      failure: final failure,
    )) {
      return AppFailure<TargetVisibilityFilter>(failure);
    }
    final visibility =
        (visibilityResult as AppSuccess<CustomerVisibilityFilter>).value;

    switch (visibility.mode) {
      case CustomerVisibilityMode.allOrganization:
        return AppSuccess<TargetVisibilityFilter>(
          TargetVisibilityFilter(
            organizationId: organizationId,
            companyId: companyId,
            userId: userId,
            mode: TargetVisibilityMode.allOrganization,
          ),
        );
      case CustomerVisibilityMode.ownCustomers:
        return AppSuccess<TargetVisibilityFilter>(
          TargetVisibilityFilter(
            organizationId: organizationId,
            companyId: companyId,
            userId: userId,
            mode: TargetVisibilityMode.ownOnly,
          ),
        );
      case CustomerVisibilityMode.teams:
        final teamsResult = await _teamRepository.listByOrganization(
          organizationId,
        );
        if (teamsResult case AppFailure<List<Team>>(failure: final failure)) {
          return AppFailure<TargetVisibilityFilter>(failure);
        }
        final teams = (teamsResult as AppSuccess<List<Team>>).value;
        final teamMemberIds = <String>{
          for (final team in teams)
            if (visibility.teamIds.contains(team.id)) ...team.memberIds,
        };
        return AppSuccess<TargetVisibilityFilter>(
          TargetVisibilityFilter(
            organizationId: organizationId,
            companyId: companyId,
            userId: userId,
            mode: TargetVisibilityMode.teams,
            teamIds: visibility.teamIds,
            teamMemberIds: teamMemberIds,
          ),
        );
      case CustomerVisibilityMode.none:
        return AppSuccess<TargetVisibilityFilter>(
          TargetVisibilityFilter.none(
            organizationId: organizationId,
            companyId: companyId,
            userId: userId,
          ),
        );
    }
  }
}
