import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/company.dart';
import '../repositories/company_repository.dart';

/// Lists every non-deleted Company of one Organization (`tasks.md`, seção
/// 3.1/3.2). Always scoped by [organizationId] — there is no "list all
/// companies across organizations" method anywhere in this feature.
@injectable
final class ListCompaniesUseCase {
  const ListCompaniesUseCase(this._repository);

  final CompanyRepository _repository;

  Future<AppResult<List<Company>>> call(String organizationId) {
    final trimmedOrganizationId = organizationId.trim();

    if (trimmedOrganizationId.isEmpty) {
      return Future<AppResult<List<Company>>>.value(
        AppFailure<List<Company>>(
          const ValidationFailure(
            'OrganizationId is required.',
            code: 'invalid_company_list_organization_id',
          ),
        ),
      );
    }

    return _repository.listByOrganization(trimmedOrganizationId);
  }
}
