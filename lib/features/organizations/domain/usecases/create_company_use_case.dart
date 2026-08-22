import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/company.dart';
import '../repositories/company_repository.dart';

/// Creates a Company under an Organization (`tasks.md`, seção 3.1/3.2).
///
/// [id] must be generated once by the caller and kept stable across retries
/// — mirrors [CreateOrganizationUseCase] so a retried create after a
/// network failure does not depend on this use case to stay idempotent.
@injectable
final class CreateCompanyUseCase {
  const CreateCompanyUseCase(this._repository);

  final CompanyRepository _repository;

  Future<AppResult<Company>> call({
    required String id,
    required String organizationId,
    required String name,
    String? legalName,
    String? taxId,
    required String createdBy,
  }) async {
    final trimmedId = id.trim();
    final trimmedOrganizationId = organizationId.trim();
    final trimmedName = name.trim();
    final trimmedCreatedBy = createdBy.trim();
    final trimmedLegalName = legalName?.trim();
    final trimmedTaxId = taxId?.trim();

    final fieldErrors = <String, String>{};
    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedName.isEmpty) fieldErrors['name'] = 'Name is required.';
    if (trimmedCreatedBy.isEmpty) {
      fieldErrors['createdBy'] = 'CreatedBy is required.';
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure<Company>(
        ValidationFailure(
          'Invalid company creation payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_company_create_payload',
        ),
      );
    }

    return _repository.create(
      id: trimmedId,
      organizationId: trimmedOrganizationId,
      name: trimmedName,
      legalName: (trimmedLegalName == null || trimmedLegalName.isEmpty)
          ? null
          : trimmedLegalName,
      taxId: (trimmedTaxId == null || trimmedTaxId.isEmpty)
          ? null
          : trimmedTaxId,
      createdBy: trimmedCreatedBy,
    );
  }
}
