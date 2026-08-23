import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../organizations/organizations.dart';
import '../entities/customer_visibility_filter.dart';

/// Resolves the Customer query contract for TASK-051 without modeling
/// Customer in TASK-045.
@injectable
final class PortfolioVisibilityService {
  const PortfolioVisibilityService(
    this._membershipRepository,
    this._teamRepository,
  );

  final MembershipRepository _membershipRepository;
  final TeamRepository _teamRepository;

  Future<AppResult<CustomerVisibilityFilter>> resolve({
    required String organizationId,
    required String companyId,
    required String userId,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedCompanyId = companyId.trim();
    final trimmedUserId = userId.trim();
    final fieldErrors = <String, String>{};

    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedCompanyId.isEmpty) {
      fieldErrors['companyId'] = 'CompanyId is required.';
    }
    if (trimmedUserId.isEmpty) {
      fieldErrors['userId'] = 'UserId is required.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<CustomerVisibilityFilter>(
        ValidationFailure(
          'Invalid portfolio visibility payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_portfolio_visibility_payload',
        ),
      );
    }

    final membershipResult = await _membershipRepository.getByUser(
      organizationId: trimmedOrganizationId,
      userId: trimmedUserId,
    );
    if (membershipResult case AppFailure<Membership>(failure: final failure)) {
      if (failure is NotFoundFailure) {
        return AppSuccess<CustomerVisibilityFilter>(
          CustomerVisibilityFilter.none(
            organizationId: trimmedOrganizationId,
            companyId: trimmedCompanyId,
            userId: trimmedUserId,
          ),
        );
      }
      return AppFailure<CustomerVisibilityFilter>(failure);
    }

    final membership = (membershipResult as AppSuccess<Membership>).value;
    if (membership.status != MembershipStatus.active) {
      return AppSuccess<CustomerVisibilityFilter>(
        CustomerVisibilityFilter.none(
          organizationId: trimmedOrganizationId,
          companyId: trimmedCompanyId,
          userId: trimmedUserId,
        ),
      );
    }

    if (membership.roleName == SystemRoleName.owner.code ||
        membership.roleName == SystemRoleName.admin.code) {
      return AppSuccess<CustomerVisibilityFilter>(
        CustomerVisibilityFilter(
          organizationId: trimmedOrganizationId,
          companyId: trimmedCompanyId,
          userId: trimmedUserId,
          mode: CustomerVisibilityMode.allOrganization,
        ),
      );
    }

    if (membership.roleName == SystemRoleName.salesManager.code) {
      final teamsResult = await _teamRepository.listByOrganization(
        trimmedOrganizationId,
      );
      if (teamsResult case AppFailure<List<Team>>(failure: final failure)) {
        return AppFailure<CustomerVisibilityFilter>(failure);
      }
      final teams = (teamsResult as AppSuccess<List<Team>>).value;
      final visibleTeamIds = <String>{
        ...membership.teamIds,
        for (final team in teams)
          if (team.managerUserId == trimmedUserId) team.id,
      };

      return AppSuccess<CustomerVisibilityFilter>(
        visibleTeamIds.isEmpty
            ? CustomerVisibilityFilter.none(
                organizationId: trimmedOrganizationId,
                companyId: trimmedCompanyId,
                userId: trimmedUserId,
              )
            : CustomerVisibilityFilter(
                organizationId: trimmedOrganizationId,
                companyId: trimmedCompanyId,
                userId: trimmedUserId,
                mode: CustomerVisibilityMode.teams,
                teamIds: visibleTeamIds,
              ),
      );
    }

    if (membership.roleName == SystemRoleName.salesRep.code) {
      return AppSuccess<CustomerVisibilityFilter>(
        CustomerVisibilityFilter(
          organizationId: trimmedOrganizationId,
          companyId: trimmedCompanyId,
          userId: trimmedUserId,
          mode: CustomerVisibilityMode.ownCustomers,
        ),
      );
    }

    return AppSuccess<CustomerVisibilityFilter>(
      CustomerVisibilityFilter.none(
        organizationId: trimmedOrganizationId,
        companyId: trimmedCompanyId,
        userId: trimmedUserId,
      ),
    );
  }
}
