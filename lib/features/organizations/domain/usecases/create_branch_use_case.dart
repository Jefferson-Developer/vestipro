import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/branch.dart';
import '../repositories/branch_repository.dart';
import '../value_objects/branch_address.dart';
import '../value_objects/branch_type.dart';

/// Creates a Branch under a Company/Organization (`tasks.md`, seção
/// 3.1/3.2 — "Loja Blumenau", "Loja Jaraguá", "Showroom São Paulo").
///
/// [id] must be generated once by the caller and kept stable across
/// retries — mirrors [CreateCompanyUseCase] so a retried create after a
/// network failure does not depend on this use case to stay idempotent.
@injectable
final class CreateBranchUseCase {
  const CreateBranchUseCase(this._repository);

  final BranchRepository _repository;

  Future<AppResult<Branch>> call({
    required String id,
    required String organizationId,
    required String companyId,
    required String name,
    required BranchType type,
    BranchAddress? address,
    required String createdBy,
  }) async {
    final trimmedId = id.trim();
    final trimmedOrganizationId = organizationId.trim();
    final trimmedCompanyId = companyId.trim();
    final trimmedName = name.trim();
    final trimmedCreatedBy = createdBy.trim();

    final fieldErrors = <String, String>{};
    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedCompanyId.isEmpty) {
      fieldErrors['companyId'] = 'CompanyId is required.';
    }
    if (trimmedName.isEmpty) fieldErrors['name'] = 'Name is required.';
    if (trimmedCreatedBy.isEmpty) {
      fieldErrors['createdBy'] = 'CreatedBy is required.';
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure<Branch>(
        ValidationFailure(
          'Invalid branch creation payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_branch_create_payload',
        ),
      );
    }

    return _repository.create(
      id: trimmedId,
      organizationId: trimmedOrganizationId,
      companyId: trimmedCompanyId,
      name: trimmedName,
      type: type,
      address: address,
      createdBy: trimmedCreatedBy,
    );
  }
}
