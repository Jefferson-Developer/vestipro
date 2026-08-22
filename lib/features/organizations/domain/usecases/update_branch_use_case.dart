import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/branch.dart';
import '../repositories/branch_repository.dart';
import '../value_objects/branch_address.dart';
import '../value_objects/branch_status.dart';
import '../value_objects/branch_type.dart';

/// Updates a Branch's mutable fields (name, type, address, status).
///
/// This use case has no parameter that could rewrite
/// [Branch.organizationId] or [Branch.companyId] — only [organizationId]/
/// [id] to select which Branch to update, never to change it — and
/// delegates to [BranchRepository.update], which is equally unable to
/// touch them.
@injectable
final class UpdateBranchUseCase {
  const UpdateBranchUseCase(this._repository);

  final BranchRepository _repository;

  Future<AppResult<Branch>> call({
    required String organizationId,
    required String id,
    required String name,
    required BranchType type,
    BranchAddress? address,
    required BranchStatus status,
    required String updatedBy,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedId = id.trim();
    final trimmedName = name.trim();
    final trimmedUpdatedBy = updatedBy.trim();

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
      return AppFailure<Branch>(
        ValidationFailure(
          'Invalid branch update payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_branch_update_payload',
        ),
      );
    }

    return _repository.update(
      organizationId: trimmedOrganizationId,
      id: trimmedId,
      name: trimmedName,
      type: type,
      address: address,
      status: status,
      updatedBy: trimmedUpdatedBy,
    );
  }
}
