import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../organizations/organizations.dart';
import '../entities/portfolio_assignment.dart';
import '../repositories/portfolio_assignment_repository.dart';

/// Creates or reassigns portfolio responsibility without touching Customer.
///
/// For `customer` scope, shared portfolios are intentionally unsupported:
/// one active assignment is kept as the primary seller contract. Reassignment
/// closes the previous active assignment as `reassigned` and creates a new
/// active assignment, preserving the assignment history and leaving all future
/// customer interactions/orders untouched.
@injectable
final class AssignPortfolioUseCase {
  const AssignPortfolioUseCase(
    this._portfolioRepository,
    this._membershipRepository,
    this._teamRepository,
  );

  final PortfolioAssignmentRepository _portfolioRepository;
  final MembershipRepository _membershipRepository;
  final TeamRepository _teamRepository;

  Future<AppResult<PortfolioAssignment>> call({
    required String id,
    required String organizationId,
    required String companyId,
    required String userId,
    required String teamId,
    required PortfolioAssignmentScope scope,
    required String assignedBy,
  }) async {
    final trimmedId = id.trim();
    final trimmedOrganizationId = organizationId.trim();
    final trimmedCompanyId = companyId.trim();
    final trimmedUserId = userId.trim();
    final trimmedTeamId = teamId.trim();
    final trimmedAssignedBy = assignedBy.trim();
    final normalizedScope = _normalizeScope(scope);

    final fieldErrors = _validate(
      id: trimmedId,
      organizationId: trimmedOrganizationId,
      companyId: trimmedCompanyId,
      userId: trimmedUserId,
      teamId: trimmedTeamId,
      scope: normalizedScope,
      assignedBy: trimmedAssignedBy,
    );
    if (fieldErrors.isNotEmpty) {
      return AppFailure<PortfolioAssignment>(
        ValidationFailure(
          'Invalid portfolio assignment payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_portfolio_assignment_payload',
        ),
      );
    }

    final sellerResult = await _membershipRepository.getByUser(
      organizationId: trimmedOrganizationId,
      userId: trimmedUserId,
    );
    if (sellerResult case AppFailure<Membership>(failure: final failure)) {
      return AppFailure<PortfolioAssignment>(failure);
    }
    final seller = (sellerResult as AppSuccess<Membership>).value;
    if (seller.status != MembershipStatus.active ||
        seller.roleName != SystemRoleName.salesRep.code) {
      return const AppFailure<PortfolioAssignment>(
        ValidationFailure(
          'Portfolio owner must be an active SALES_REP.',
          fieldErrors: <String, String>{
            'userId': 'Select an active SALES_REP.',
          },
          code: 'invalid_portfolio_seller',
        ),
      );
    }

    final teamResult = await _teamRepository.getById(
      organizationId: trimmedOrganizationId,
      id: trimmedTeamId,
    );
    if (teamResult case AppFailure<Team>(failure: final failure)) {
      return AppFailure<PortfolioAssignment>(failure);
    }
    final team = (teamResult as AppSuccess<Team>).value;
    if (!team.memberIds.contains(trimmedUserId)) {
      return const AppFailure<PortfolioAssignment>(
        ValidationFailure(
          'Seller must belong to the selected Team.',
          fieldErrors: <String, String>{
            'teamId': 'Select a Team that contains this seller.',
          },
          code: 'portfolio_seller_not_in_team',
        ),
      );
    }

    if (normalizedScope.isCustomer) {
      final existingResult = await _portfolioRepository
          .findActiveCustomerAssignment(
            organizationId: trimmedOrganizationId,
            companyId: trimmedCompanyId,
            customerId: normalizedScope.customerId!,
          );
      if (existingResult case AppFailure<PortfolioAssignment?>(
        failure: final failure,
      )) {
        return AppFailure<PortfolioAssignment>(failure);
      }
      final existing =
          (existingResult as AppSuccess<PortfolioAssignment?>).value;
      if (existing != null) {
        if (existing.userId == trimmedUserId &&
            existing.teamId == trimmedTeamId) {
          return AppSuccess<PortfolioAssignment>(existing);
        }
        final endResult = await _portfolioRepository.endAssignment(
          organizationId: trimmedOrganizationId,
          id: existing.id,
          status: PortfolioAssignmentStatus.reassigned,
          endedAt: DateTime.now().toUtc(),
          endedBy: trimmedAssignedBy,
        );
        if (endResult case AppFailure<PortfolioAssignment>(
          failure: final failure,
        )) {
          return AppFailure<PortfolioAssignment>(failure);
        }
      }
    }

    final now = DateTime.now().toUtc();
    return _portfolioRepository.create(
      PortfolioAssignment(
        id: trimmedId,
        organizationId: trimmedOrganizationId,
        companyId: trimmedCompanyId,
        userId: trimmedUserId,
        teamId: trimmedTeamId,
        scope: normalizedScope,
        status: PortfolioAssignmentStatus.active,
        version: 1,
        createdAt: now,
        createdBy: trimmedAssignedBy,
        updatedAt: now,
        updatedBy: trimmedAssignedBy,
      ),
    );
  }

  PortfolioAssignmentScope _normalizeScope(PortfolioAssignmentScope scope) {
    return switch (scope.type) {
      PortfolioAssignmentScopeType.customer =>
        PortfolioAssignmentScope.customer(scope.customerId?.trim() ?? ''),
      PortfolioAssignmentScopeType.criteria =>
        PortfolioAssignmentScope.criteria(
          region: _nullableTrim(scope.region),
          segment: _nullableTrim(scope.segment),
        ),
    };
  }

  String? _nullableTrim(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  Map<String, String> _validate({
    required String id,
    required String organizationId,
    required String companyId,
    required String userId,
    required String teamId,
    required PortfolioAssignmentScope scope,
    required String assignedBy,
  }) {
    final fieldErrors = <String, String>{};
    if (id.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (organizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (companyId.isEmpty) fieldErrors['companyId'] = 'CompanyId is required.';
    if (userId.isEmpty) fieldErrors['userId'] = 'UserId is required.';
    if (teamId.isEmpty) fieldErrors['teamId'] = 'TeamId is required.';
    if (assignedBy.isEmpty) {
      fieldErrors['assignedBy'] = 'AssignedBy is required.';
    }

    switch (scope.type) {
      case PortfolioAssignmentScopeType.customer:
        if (scope.customerId == null || scope.customerId!.trim().isEmpty) {
          fieldErrors['customerId'] = 'CustomerId is required.';
        }
      case PortfolioAssignmentScopeType.criteria:
        final hasRegion = scope.region != null && scope.region!.isNotEmpty;
        final hasSegment = scope.segment != null && scope.segment!.isNotEmpty;
        if (!hasRegion && !hasSegment) {
          fieldErrors['criteria'] = 'Inform region or segment.';
        }
    }

    return fieldErrors;
  }
}
