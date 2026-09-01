import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../../organizations/organizations.dart';
import '../entities/ranking_peer_scope.dart';
import '../entities/target_visibility_filter.dart';
import '../value_objects/ranking_dimension_type.dart';

/// The `Membership.roleName` a ranking comercial (TASK-118) of
/// [RankingDimensionType.salesRep] compares — deliberately not every role
/// with a `Target`, only the sales reps themselves (a manager's own personal
/// target, if any, is compared through [RankingDimensionType.team] instead).
const String _salesRepRoleName = 'SALES_REP';

/// Resolves *who the caller's peers are* for a ranking comercial (TASK-118,
/// EPIC-15) — a distinct question from [TargetVisibilityFilter]'s "may I
/// query this one dimension" (TASK-116), reusing that filter's already-
/// resolved [TargetVisibilityMode]/`teamIds`/`teamMemberIds` instead of
/// re-deriving the OWNER/ADMIN/SALES_MANAGER/SALES_REP branching a second
/// time.
///
/// This is the RBAC-critical boundary of the whole feature: whichever ids
/// end up in [RankingPeerScope.peerIds] are the only ids
/// `RankingDashboardCubit` will ever fetch a `Target`/achievement for — a
/// peer never resolved here can never leak into a ranking, regardless of
/// what `RankingCalculationService`/`RankingAccessLevel` decide to redact
/// afterwards. Never trusts the UI: every method re-resolves from
/// [TargetVisibilityFilter], the same defense-in-depth precedent
/// `TargetVisibilityService`/`TargetDashboardCubit` already established.
@injectable
final class RankingPeerResolverService {
  const RankingPeerResolverService(
    this._membershipRepository,
    this._teamRepository,
  );

  final MembershipRepository _membershipRepository;
  final TeamRepository _teamRepository;

  Future<AppResult<RankingPeerScope>> resolve({
    required String organizationId,
    required String userId,
    required RankingDimensionType dimensionType,
    required TargetVisibilityFilter visibilityFilter,
  }) async {
    if (!visibilityFilter.canViewAny) {
      return AppSuccess<RankingPeerScope>(
        RankingPeerScope(
          dimensionType: dimensionType,
          peerIds: const <String>{},
        ),
      );
    }

    return switch (dimensionType) {
      RankingDimensionType.team => _resolveTeamPeers(
        organizationId: organizationId,
        visibilityFilter: visibilityFilter,
      ),
      RankingDimensionType.salesRep => _resolveSalesRepPeers(
        organizationId: organizationId,
        userId: userId,
        visibilityFilter: visibilityFilter,
      ),
    };
  }

  Future<AppResult<RankingPeerScope>> _resolveTeamPeers({
    required String organizationId,
    required TargetVisibilityFilter visibilityFilter,
  }) async {
    switch (visibilityFilter.mode) {
      case TargetVisibilityMode.allOrganization:
        final teamsResult = await _teamRepository.listByOrganization(
          organizationId,
        );
        if (teamsResult case AppFailure<List<Team>>(failure: final failure)) {
          return AppFailure<RankingPeerScope>(failure);
        }
        final teams = (teamsResult as AppSuccess<List<Team>>).value;
        return AppSuccess<RankingPeerScope>(
          RankingPeerScope(
            dimensionType: RankingDimensionType.team,
            peerIds: teams.map((team) => team.id).toSet(),
          ),
        );
      case TargetVisibilityMode.teams:
        return AppSuccess<RankingPeerScope>(
          RankingPeerScope(
            dimensionType: RankingDimensionType.team,
            peerIds: visibilityFilter.teamIds,
          ),
        );
      case TargetVisibilityMode.ownOnly:
      case TargetVisibilityMode.none:
        // A SALES_REP never ranks by team (the UI never offers this
        // dimension to them either — `RankingDashboardState
        // .canPickDimension` mirrors TASK-116's own precedent), so this is
        // defense-in-depth: an empty scope, never an error.
        return AppSuccess<RankingPeerScope>(
          const RankingPeerScope(
            dimensionType: RankingDimensionType.team,
            peerIds: <String>{},
          ),
        );
    }
  }

  Future<AppResult<RankingPeerScope>> _resolveSalesRepPeers({
    required String organizationId,
    required String userId,
    required TargetVisibilityFilter visibilityFilter,
  }) async {
    switch (visibilityFilter.mode) {
      case TargetVisibilityMode.allOrganization:
        final membershipsResult = await _membershipRepository
            .listByOrganization(organizationId);
        if (membershipsResult case AppFailure<List<Membership>>(
          failure: final failure,
        )) {
          return AppFailure<RankingPeerScope>(failure);
        }
        final memberships =
            (membershipsResult as AppSuccess<List<Membership>>).value;
        final peerIds = memberships
            .where(
              (membership) =>
                  membership.status == MembershipStatus.active &&
                  membership.roleName == _salesRepRoleName,
            )
            .map((membership) => membership.userId)
            .toSet();
        return AppSuccess<RankingPeerScope>(
          RankingPeerScope(
            dimensionType: RankingDimensionType.salesRep,
            peerIds: peerIds,
          ),
        );
      case TargetVisibilityMode.teams:
        // Already resolved by `TargetVisibilityService` from the exact same
        // managed teams — never re-derived here.
        return AppSuccess<RankingPeerScope>(
          RankingPeerScope(
            dimensionType: RankingDimensionType.salesRep,
            peerIds: visibilityFilter.teamMemberIds,
          ),
        );
      case TargetVisibilityMode.ownOnly:
        final teamsResult = await _teamRepository.listByOrganization(
          organizationId,
        );
        if (teamsResult case AppFailure<List<Team>>(failure: final failure)) {
          return AppFailure<RankingPeerScope>(failure);
        }
        final teams = (teamsResult as AppSuccess<List<Team>>).value;
        final ownTeams = teams.where((team) => team.memberIds.contains(userId));
        final peerIds = <String>{
          for (final team in ownTeams) ...team.memberIds,
        };
        // A SALES_REP in no Team yet still gets to see their own ranking of
        // one — never an empty scope just because they are not teamed up.
        if (peerIds.isEmpty) peerIds.add(userId);
        return AppSuccess<RankingPeerScope>(
          RankingPeerScope(
            dimensionType: RankingDimensionType.salesRep,
            peerIds: peerIds,
          ),
        );
      case TargetVisibilityMode.none:
        return AppSuccess<RankingPeerScope>(
          const RankingPeerScope(
            dimensionType: RankingDimensionType.salesRep,
            peerIds: <String>{},
          ),
        );
    }
  }
}
