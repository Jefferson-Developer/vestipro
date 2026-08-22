import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/branch.dart';
import '../repositories/branch_repository.dart';

/// Lists every non-deleted Branch of one Company within one Organization
/// (`tasks.md`, seção 3.1/3.2). Always scoped by both [organizationId] and
/// [companyId] — there is no "list all branches across companies" method
/// anywhere in this feature.
@injectable
final class ListBranchesByCompanyUseCase {
  const ListBranchesByCompanyUseCase(this._repository);

  final BranchRepository _repository;

  Future<AppResult<List<Branch>>> call({
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
      return Future<AppResult<List<Branch>>>.value(
        AppFailure<List<Branch>>(
          ValidationFailure(
            'Invalid branch listing payload.',
            fieldErrors: fieldErrors,
            code: 'invalid_branch_list_payload',
          ),
        ),
      );
    }

    return _repository.listByCompany(
      organizationId: trimmedOrganizationId,
      companyId: trimmedCompanyId,
    );
  }
}
