import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../../organizations/organizations.dart';
import '../../../users/users.dart';
import '../entities/order_visibility_filter.dart';

/// Resolves how much of an organization's Order collection the signed-in
/// caller may see (TASK-102): every Order for OWNER/ADMIN, the orders of the
/// sellers under a SALES_MANAGER's own teams, or only the caller's own
/// orders for a SALES_REP.
///
/// Reuses [PortfolioVisibilityService] for the exact same
/// OWNER/ADMIN/SALES_MANAGER/SALES_REP role-branching TASK-051 already
/// modeled for Customer visibility instead of re-implementing it — Order
/// itself has no denormalized `teamId` the way Customer does (one seller can
/// belong to more than one team), so this service additionally resolves the
/// manager's visible [CustomerVisibilityFilter.teamIds] into the concrete
/// set of seller user ids via [Team.memberIds].
///
/// Deliberately reads [TeamRepository] instead of
/// `MembershipRepository.listByOrganization` for that resolution: bulk
/// `members` `list` queries are restricted by `firestore.rules` to
/// `user.changeRole` (OWNER/ADMIN only, TASK-042) — a SALES_MANAGER may
/// never issue one — while every active member may freely read every `Team`
/// document, which already denormalizes [Team.memberIds].
///
/// This resolution is UX/defense-in-depth only: `firestore.rules`
/// (`canReadOrder`/`managerCanReadOrder`) independently re-verifies the same
/// decision against each Order document's real `sellerId` (via a `get()` of
/// that seller's own Membership, always allowed for any active member),
/// never trusting this service's output as the sole authorization.
@injectable
final class OrderVisibilityService {
  const OrderVisibilityService(
    this._portfolioVisibilityService,
    this._teamRepository,
  );

  final PortfolioVisibilityService _portfolioVisibilityService;
  final TeamRepository _teamRepository;

  Future<AppResult<OrderVisibilityFilter>> resolve({
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
      return AppFailure<OrderVisibilityFilter>(failure);
    }
    final visibility =
        (visibilityResult as AppSuccess<CustomerVisibilityFilter>).value;

    switch (visibility.mode) {
      case CustomerVisibilityMode.allOrganization:
        return const AppSuccess<OrderVisibilityFilter>(
          OrderVisibilityFilter(mode: OrderVisibilityMode.allCompany),
        );
      case CustomerVisibilityMode.ownCustomers:
        return AppSuccess<OrderVisibilityFilter>(
          OrderVisibilityFilter(
            mode: OrderVisibilityMode.ownOnly,
            sellerIds: <String>{userId},
          ),
        );
      case CustomerVisibilityMode.teams:
        final teamsResult = await _teamRepository.listByOrganization(
          organizationId,
        );
        if (teamsResult case AppFailure<List<Team>>(failure: final failure)) {
          return AppFailure<OrderVisibilityFilter>(failure);
        }
        final teams = (teamsResult as AppSuccess<List<Team>>).value;
        final sellerIds = <String>{
          for (final team in teams)
            if (visibility.teamIds.contains(team.id)) ...team.memberIds,
        };
        if (sellerIds.isEmpty) {
          return const AppSuccess<OrderVisibilityFilter>(
            OrderVisibilityFilter.none(),
          );
        }
        return AppSuccess<OrderVisibilityFilter>(
          OrderVisibilityFilter(
            mode: OrderVisibilityMode.sellerSubset,
            sellerIds: sellerIds,
          ),
        );
      case CustomerVisibilityMode.none:
        return const AppSuccess<OrderVisibilityFilter>(
          OrderVisibilityFilter.none(),
        );
    }
  }
}
