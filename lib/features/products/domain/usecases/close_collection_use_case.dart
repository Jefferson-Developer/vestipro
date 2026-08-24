import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/collection.dart';
import '../repositories/collection_repository.dart';
import '../value_objects/collection_status.dart';

/// Closes an active `Collection` (TASK-066): transitions it to
/// `CollectionStatus.closed`, never deleting it nor any Product association
/// (see `Collection`'s own doc). Idempotent — closing an already-closed
/// Collection succeeds without writing again.
@injectable
final class CloseCollectionUseCase {
  CloseCollectionUseCase(this._repository);

  final CollectionRepository _repository;

  Future<AppResult<Collection>> call({
    required String organizationId,
    required String id,
    required String updatedBy,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedId = id.trim();
    final trimmedUpdatedBy = updatedBy.trim();

    final fieldErrors = <String, String>{};
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedUpdatedBy.isEmpty) {
      fieldErrors['updatedBy'] = 'UpdatedBy is required.';
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure<Collection>(
        ValidationFailure(
          'Invalid collection close payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_collection_close_payload',
        ),
      );
    }

    final existingResult = await _repository.getById(
      organizationId: trimmedOrganizationId,
      id: trimmedId,
    );
    if (existingResult is AppFailure<Collection>) return existingResult;
    final existing = (existingResult as AppSuccess<Collection>).value;

    if (existing.status == CollectionStatus.closed) {
      return AppSuccess<Collection>(existing);
    }

    return _repository.close(
      organizationId: trimmedOrganizationId,
      id: trimmedId,
      updatedBy: trimmedUpdatedBy,
    );
  }
}
