import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../organizations/organizations.dart';
import '../entities/executive_dashboard_visibility_filter.dart';

/// Resolves how much of an organization's companies/teams the signed-in
/// caller may pick as the Executive Dashboard's scope filter (TASK-134):
/// every `Company`/`Team` for OWNER/ADMIN/FINANCE (the "gestores seniores"
/// the dashboard's own Objetivo names), only the caller's own managed
/// team(s)/company(ies) for a SALES_MANAGER.
///
/// Deliberately its own service (not a reuse of `PortfolioVisibilityService`/
/// `TargetVisibilityService`): unlike those, FINANCE must resolve to full
/// visibility here (it already holds `Capability.reportViewSensitive`, the
/// same capability gating every TASK-133 aggregation read at the Firestore
/// Rules layer — a role allowed to read the underlying data server-side has
/// no reason to be restricted to "own scope" client-side), while
/// `PortfolioVisibilityService` has no FINANCE branch at all (falls through
/// to `.none`, correct for *its* domain — a customer portfolio — but wrong
/// for this one).
@injectable
class ExecutiveDashboardVisibilityService {
  const ExecutiveDashboardVisibilityService(
    this._membershipRepository,
    this._teamRepository,
  );

  final MembershipRepository _membershipRepository;
  final TeamRepository _teamRepository;

  Future<AppResult<ExecutiveDashboardVisibilityFilter>> resolve({
    required String organizationId,
    required String userId,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedUserId = userId.trim();
    final fieldErrors = <String, String>{};

    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedUserId.isEmpty) {
      fieldErrors['userId'] = 'UserId is required.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<ExecutiveDashboardVisibilityFilter>(
        ValidationFailure(
          'Invalid executive dashboard visibility payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_executive_dashboard_visibility_payload',
        ),
      );
    }

    final membershipResult = await _membershipRepository.getByUser(
      organizationId: trimmedOrganizationId,
      userId: trimmedUserId,
    );
    if (membershipResult case AppFailure<Membership>(failure: final failure)) {
      if (failure is NotFoundFailure) {
        return AppSuccess<ExecutiveDashboardVisibilityFilter>(
          ExecutiveDashboardVisibilityFilter.none(
            organizationId: trimmedOrganizationId,
            userId: trimmedUserId,
          ),
        );
      }
      return AppFailure<ExecutiveDashboardVisibilityFilter>(failure);
    }

    final membership = (membershipResult as AppSuccess<Membership>).value;
    if (membership.status != MembershipStatus.active) {
      return AppSuccess<ExecutiveDashboardVisibilityFilter>(
        ExecutiveDashboardVisibilityFilter.none(
          organizationId: trimmedOrganizationId,
          userId: trimmedUserId,
        ),
      );
    }

    final isConsolidatedRole =
        membership.roleName == SystemRoleName.owner.code ||
        membership.roleName == SystemRoleName.admin.code ||
        membership.roleName == SystemRoleName.finance.code;
    if (isConsolidatedRole) {
      return AppSuccess<ExecutiveDashboardVisibilityFilter>(
        ExecutiveDashboardVisibilityFilter(
          organizationId: trimmedOrganizationId,
          userId: trimmedUserId,
          mode: ExecutiveDashboardVisibilityMode.allOrganization,
        ),
      );
    }

    if (membership.roleName == SystemRoleName.salesManager.code) {
      final teamsResult = await _teamRepository.listByOrganization(
        trimmedOrganizationId,
      );
      if (teamsResult case AppFailure<List<Team>>(failure: final failure)) {
        return AppFailure<ExecutiveDashboardVisibilityFilter>(failure);
      }
      final teams = (teamsResult as AppSuccess<List<Team>>).value;
      final managedTeams = teams.where(
        (team) =>
            membership.teamIds.contains(team.id) ||
            team.managerUserId == trimmedUserId,
      );
      final allowedTeamIds = <String>{for (final team in managedTeams) team.id};
      final allowedCompanyIds = <String>{
        for (final team in managedTeams)
          if (team.companyId != null && team.companyId!.isNotEmpty)
            team.companyId!,
      };

      return AppSuccess<ExecutiveDashboardVisibilityFilter>(
        allowedTeamIds.isEmpty
            ? ExecutiveDashboardVisibilityFilter.none(
                organizationId: trimmedOrganizationId,
                userId: trimmedUserId,
              )
            : ExecutiveDashboardVisibilityFilter(
                organizationId: trimmedOrganizationId,
                userId: trimmedUserId,
                mode: ExecutiveDashboardVisibilityMode.ownScope,
                allowedCompanyIds: allowedCompanyIds,
                allowedTeamIds: allowedTeamIds,
              ),
      );
    }

    // SALES_REP/SALES_ASSISTANT/READ_ONLY (and any future/custom role) never
    // hold `Capability.reportViewSensitive` (`RolePermissionMatrix`), so
    // `ExecutiveDashboardPage`'s own capability gate already keeps them from
    // reaching this screen at all — resolving `.none` here is the safe,
    // explicit default, never an implicit "some scope".
    return AppSuccess<ExecutiveDashboardVisibilityFilter>(
      ExecutiveDashboardVisibilityFilter.none(
        organizationId: trimmedOrganizationId,
        userId: trimmedUserId,
      ),
    );
  }
}
