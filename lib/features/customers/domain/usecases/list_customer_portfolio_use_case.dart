import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../users/users.dart';
import '../entities/customer_portfolio_filters.dart';
import '../entities/customer_portfolio_page_result.dart';
import '../repositories/customer_repository.dart';

@injectable
class ListCustomerPortfolioUseCase {
  const ListCustomerPortfolioUseCase(
    this._customerRepository,
    this._visibilityService,
    this._assignmentRepository,
  );

  final CustomerRepository _customerRepository;
  final PortfolioVisibilityService _visibilityService;
  final PortfolioAssignmentRepository _assignmentRepository;

  Future<AppResult<CustomerPortfolioPageResult>> call({
    required String organizationId,
    required String companyId,
    required String userId,
    CustomerPortfolioFilters filters = CustomerPortfolioFilters.empty,
    String searchQuery = '',
    String? cursor,
    int limit = 20,
    DateTime? now,
  }) async {
    final normalizedOrganizationId = organizationId.trim();
    final normalizedCompanyId = companyId.trim();
    final normalizedUserId = userId.trim();
    final fieldErrors = <String, String>{};

    if (normalizedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (normalizedCompanyId.isEmpty) {
      fieldErrors['companyId'] = 'CompanyId is required.';
    }
    if (normalizedUserId.isEmpty) {
      fieldErrors['userId'] = 'UserId is required.';
    }
    if (limit <= 0 || limit > 100) {
      fieldErrors['limit'] = 'Limit must be between 1 and 100.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<CustomerPortfolioPageResult>(
        ValidationFailure(
          'Invalid customer portfolio payload.',
          code: 'invalid_customer_portfolio_payload',
          fieldErrors: fieldErrors,
        ),
      );
    }

    final visibilityResult = await _visibilityService.resolve(
      organizationId: normalizedOrganizationId,
      companyId: normalizedCompanyId,
      userId: normalizedUserId,
    );
    if (visibilityResult case AppFailure<CustomerVisibilityFilter>(
      failure: final failure,
    )) {
      return AppFailure<CustomerPortfolioPageResult>(failure);
    }
    final visibility =
        (visibilityResult as AppSuccess<CustomerVisibilityFilter>).value;
    if (!visibility.canReadAny) {
      return const AppFailure<CustomerPortfolioPageResult>(
        PermissionFailure(
          'User has no visible customer portfolio.',
          code: 'customer_portfolio_not_visible',
        ),
      );
    }

    final assignmentsResult = await _loadAssignments(visibility);
    if (assignmentsResult case AppFailure<List<PortfolioAssignment>>(
      failure: final failure,
    )) {
      return AppFailure<CustomerPortfolioPageResult>(failure);
    }
    final assignments =
        (assignmentsResult as AppSuccess<List<PortfolioAssignment>>).value;
    if (visibility.mode == CustomerVisibilityMode.ownCustomers &&
        assignments.isEmpty) {
      return const AppFailure<CustomerPortfolioPageResult>(
        PermissionFailure(
          'Sales representative has no active customer portfolio assignment.',
          code: 'customer_portfolio_assignment_required',
        ),
      );
    }

    return _customerRepository.listPortfolioPage(
      visibility: visibility,
      activeAssignments: assignments,
      filters: filters.normalized(),
      searchQuery: searchQuery.trim(),
      cursor: cursor?.trim().isEmpty ?? true ? null : cursor!.trim(),
      limit: limit,
      now: now ?? DateTime.now().toUtc(),
    );
  }

  Future<AppResult<List<PortfolioAssignment>>> _loadAssignments(
    CustomerVisibilityFilter visibility,
  ) {
    return switch (visibility.mode) {
      CustomerVisibilityMode.allOrganization =>
        Future<AppResult<List<PortfolioAssignment>>>.value(
          const AppSuccess<List<PortfolioAssignment>>(<PortfolioAssignment>[]),
        ),
      CustomerVisibilityMode.teams =>
        _assignmentRepository
            .listActiveByOrganization(
              organizationId: visibility.organizationId,
              companyId: visibility.companyId,
            )
            .then(
              (result) => result.fold(
                onSuccess: (assignments) =>
                    AppSuccess<List<PortfolioAssignment>>(
                      assignments
                          .where(
                            (assignment) =>
                                visibility.teamIds.contains(assignment.teamId),
                          )
                          .toList(growable: false),
                    ),
                onFailure: AppFailure<List<PortfolioAssignment>>.new,
              ),
            ),
      CustomerVisibilityMode.ownCustomers =>
        _assignmentRepository.listActiveByUser(
          organizationId: visibility.organizationId,
          companyId: visibility.companyId,
          userId: visibility.userId,
        ),
      CustomerVisibilityMode.none =>
        Future<AppResult<List<PortfolioAssignment>>>.value(
          const AppSuccess<List<PortfolioAssignment>>(<PortfolioAssignment>[]),
        ),
    };
  }
}
