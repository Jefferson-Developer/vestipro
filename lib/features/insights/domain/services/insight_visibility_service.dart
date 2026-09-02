import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../../organizations/organizations.dart';
import '../../../users/users.dart';
import '../entities/insight_visibility_filter.dart';

/// Resolves how much of an organization's `Insight` set the signed-in
/// caller may view on the Central de Oportunidades (TASK-132): every
/// `recipientUserId` for OWNER/ADMIN, the caller's own plus their
/// teammates' for a SALES_MANAGER, or only the caller's own for a
/// SALES_REP.
///
/// Reuses [PortfolioVisibilityService] for the exact same
/// OWNER/ADMIN/SALES_MANAGER/SALES_REP role-branching TASK-051 already
/// modeled for `Customer` visibility instead of re-implementing it —
/// mirroring `TargetVisibilityService`'s own precedent for `Target`.
/// `Insight` has no `teamId`, only a denormalized `recipientUserId`, so
/// this service additionally resolves the manager's visible
/// [CustomerVisibilityFilter.teamIds] into the concrete set of teammate
/// user ids via [Team.memberIds], exactly like `TargetVisibilityService`
/// does.
///
/// This resolution is UX/defense-in-depth only: once `Insight` gets
/// Firestore Security Rules of its own, they must independently re-verify
/// the same decision, never trusting this service's output as the sole
/// authorization.
@injectable
final class InsightVisibilityService {
  const InsightVisibilityService(
    this._portfolioVisibilityService,
    this._teamRepository,
  );

  final PortfolioVisibilityService _portfolioVisibilityService;
  final TeamRepository _teamRepository;

  Future<AppResult<InsightVisibilityFilter>> resolve({
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
      return AppFailure<InsightVisibilityFilter>(failure);
    }
    final visibility =
        (visibilityResult as AppSuccess<CustomerVisibilityFilter>).value;

    switch (visibility.mode) {
      case CustomerVisibilityMode.allOrganization:
        return AppSuccess<InsightVisibilityFilter>(
          InsightVisibilityFilter(
            organizationId: organizationId,
            userId: userId,
            mode: InsightVisibilityMode.allOrganization,
          ),
        );
      case CustomerVisibilityMode.ownCustomers:
        return AppSuccess<InsightVisibilityFilter>(
          InsightVisibilityFilter(
            organizationId: organizationId,
            userId: userId,
            mode: InsightVisibilityMode.ownOnly,
          ),
        );
      case CustomerVisibilityMode.teams:
        final teamsResult = await _teamRepository.listByOrganization(
          organizationId,
        );
        if (teamsResult case AppFailure<List<Team>>(failure: final failure)) {
          return AppFailure<InsightVisibilityFilter>(failure);
        }
        final teams = (teamsResult as AppSuccess<List<Team>>).value;
        final teamMemberIds = <String>{
          for (final team in teams)
            if (visibility.teamIds.contains(team.id)) ...team.memberIds,
        }..remove(userId);
        return AppSuccess<InsightVisibilityFilter>(
          InsightVisibilityFilter(
            organizationId: organizationId,
            userId: userId,
            mode: InsightVisibilityMode.teams,
            teamMemberIds: teamMemberIds,
          ),
        );
      case CustomerVisibilityMode.none:
        return AppSuccess<InsightVisibilityFilter>(
          InsightVisibilityFilter.none(
            organizationId: organizationId,
            userId: userId,
          ),
        );
    }
  }
}
