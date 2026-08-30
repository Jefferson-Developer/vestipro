import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../users/users.dart';

/// Defense-in-depth guard for TASK-096's business rule: "o cliente
/// selecionado deve pertencer à carteira do vendedor autenticado (ou ele ter
/// permissão explícita) — validado tanto na UI (ocultar) quanto no
/// domain/Functions".
///
/// The "novo pedido" screen already only ever lets a seller pick a customer
/// out of `CustomerPortfolioPage`/`ListCustomerPortfolioUseCase`'s own
/// carteira-scoped results (the UI half of that rule), but a customer id can
/// still reach [StartOrderDraftForCustomerUseCase] through a
/// deep link/resumed draft, so this use case independently re-derives the
/// same [PortfolioVisibilityService] decision for that one customer id —
/// reusing the exact same visibility/assignment primitives
/// `ListCustomerPortfolioUseCase` composes, rather than reimplementing the
/// per-role branching a second time.
@injectable
final class EnsureCustomerInSellerPortfolioUseCase {
  const EnsureCustomerInSellerPortfolioUseCase(
    this._visibilityService,
    this._assignmentRepository,
  );

  final PortfolioVisibilityService _visibilityService;
  final PortfolioAssignmentRepository _assignmentRepository;

  Future<AppResult<bool>> call({
    required String organizationId,
    required String companyId,
    required String userId,
    required String customerId,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedCompanyId = companyId.trim();
    final trimmedUserId = userId.trim();
    final trimmedCustomerId = customerId.trim();
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
    if (trimmedCustomerId.isEmpty) {
      fieldErrors['customerId'] = 'CustomerId is required.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<bool>(
        ValidationFailure(
          'Invalid customer portfolio access check payload.',
          code: 'invalid_customer_portfolio_access_payload',
          fieldErrors: fieldErrors,
        ),
      );
    }

    final visibilityResult = await _visibilityService.resolve(
      organizationId: trimmedOrganizationId,
      companyId: trimmedCompanyId,
      userId: trimmedUserId,
    );
    if (visibilityResult case AppFailure<CustomerVisibilityFilter>(
      failure: final failure,
    )) {
      return AppFailure<bool>(failure);
    }
    final visibility =
        (visibilityResult as AppSuccess<CustomerVisibilityFilter>).value;

    return switch (visibility.mode) {
      CustomerVisibilityMode.allOrganization => const AppSuccess<bool>(true),
      CustomerVisibilityMode.none => const AppSuccess<bool>(false),
      CustomerVisibilityMode.teams ||
      CustomerVisibilityMode.ownCustomers => await _hasActiveAssignment(
        organizationId: trimmedOrganizationId,
        companyId: trimmedCompanyId,
        customerId: trimmedCustomerId,
        visibility: visibility,
      ),
    };
  }

  Future<AppResult<bool>> _hasActiveAssignment({
    required String organizationId,
    required String companyId,
    required String customerId,
    required CustomerVisibilityFilter visibility,
  }) async {
    final assignmentResult = await _assignmentRepository
        .findActiveCustomerAssignment(
          organizationId: organizationId,
          companyId: companyId,
          customerId: customerId,
        );
    if (assignmentResult case AppFailure<PortfolioAssignment?>(
      failure: final failure,
    )) {
      return AppFailure<bool>(failure);
    }
    final assignment =
        (assignmentResult as AppSuccess<PortfolioAssignment?>).value;
    if (assignment == null) return const AppSuccess<bool>(false);

    return AppSuccess<bool>(switch (visibility.mode) {
      CustomerVisibilityMode.teams => visibility.teamIds.contains(
        assignment.teamId,
      ),
      CustomerVisibilityMode.ownCustomers =>
        assignment.userId == visibility.userId,
      CustomerVisibilityMode.allOrganization ||
      CustomerVisibilityMode.none => false,
    });
  }
}
