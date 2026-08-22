import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/company.dart';
import '../repositories/company_repository.dart';
import '../value_objects/company_status.dart';

/// Updates a Company's mutable fields (name, legal name, tax id, status).
///
/// This use case has no parameter that could rewrite [Company.organizationId]
/// — only [organizationId]/[id] to select which Company to update, never to
/// change it — and delegates to [CompanyRepository.update], which is
/// equally unable to touch it.
@injectable
final class UpdateCompanyUseCase {
  const UpdateCompanyUseCase(this._repository);

  final CompanyRepository _repository;

  Future<AppResult<Company>> call({
    required String organizationId,
    required String id,
    required String name,
    String? legalName,
    String? taxId,
    required CompanyStatus status,
    required String updatedBy,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedId = id.trim();
    final trimmedName = name.trim();
    final trimmedUpdatedBy = updatedBy.trim();
    final trimmedLegalName = legalName?.trim();
    final trimmedTaxId = taxId?.trim();

    final fieldErrors = <String, String>{};
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedName.isEmpty) fieldErrors['name'] = 'Name is required.';
    if (trimmedUpdatedBy.isEmpty) {
      fieldErrors['updatedBy'] = 'UpdatedBy is required.';
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure<Company>(
        ValidationFailure(
          'Invalid company update payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_company_update_payload',
        ),
      );
    }

    return _repository.update(
      organizationId: trimmedOrganizationId,
      id: trimmedId,
      name: trimmedName,
      legalName: (trimmedLegalName == null || trimmedLegalName.isEmpty)
          ? null
          : trimmedLegalName,
      taxId: (trimmedTaxId == null || trimmedTaxId.isEmpty)
          ? null
          : trimmedTaxId,
      status: status,
      updatedBy: trimmedUpdatedBy,
    );
  }
}
