import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/portfolio_assignment.dart';
import '../repositories/portfolio_assignment_repository.dart';

@injectable
final class ListPortfolioAssignmentsUseCase {
  const ListPortfolioAssignmentsUseCase(this._repository);

  final PortfolioAssignmentRepository _repository;

  Future<AppResult<List<PortfolioAssignment>>> call({
    required String organizationId,
    required String companyId,
  }) {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedCompanyId = companyId.trim();
    final fieldErrors = <String, String>{};
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedCompanyId.isEmpty) {
      fieldErrors['companyId'] = 'CompanyId is required.';
    }
    if (fieldErrors.isNotEmpty) {
      return Future.value(
        AppFailure<List<PortfolioAssignment>>(
          ValidationFailure(
            'Invalid portfolio assignment list payload.',
            fieldErrors: fieldErrors,
            code: 'invalid_portfolio_assignment_list_payload',
          ),
        ),
      );
    }

    return _repository.listActiveByOrganization(
      organizationId: trimmedOrganizationId,
      companyId: trimmedCompanyId,
    );
  }
}
