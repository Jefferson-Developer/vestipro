import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/season.dart';
import '../repositories/season_repository.dart';

/// Soft-deletes a `Season` vocabulary entry (TASK-066).
///
/// Blocked (`ConflictFailure`, code `season_in_use`) whenever any
/// non-deleted `Collection` of the Organization still references this
/// Season — deleting the vocabulary entry from under an active/closed
/// Collection would leave it pointing at nothing, the same
/// dangling-reference risk `DeleteTeamUseCase`'s
/// `hasCommercialLinks` guard prevents for Team.
@injectable
final class DeleteSeasonUseCase {
  DeleteSeasonUseCase(this._repository);

  final SeasonRepository _repository;

  Future<AppResult<Season>> call({
    required String organizationId,
    required String id,
    required String deletedBy,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedId = id.trim();
    final trimmedDeletedBy = deletedBy.trim();

    final fieldErrors = <String, String>{};
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedDeletedBy.isEmpty) {
      fieldErrors['deletedBy'] = 'DeletedBy is required.';
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure<Season>(
        ValidationFailure(
          'Invalid season delete payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_season_delete_payload',
        ),
      );
    }

    final hasCollectionsResult = await _repository.hasCollections(
      organizationId: trimmedOrganizationId,
      seasonId: trimmedId,
    );
    if (hasCollectionsResult is AppFailure<bool>) {
      return AppFailure<Season>(hasCollectionsResult.failure);
    }
    if ((hasCollectionsResult as AppSuccess<bool>).value) {
      return const AppFailure<Season>(
        ConflictFailure(
          'Esta estação está em uso por uma ou mais coleções e não pode '
          'ser excluída.',
          code: 'season_in_use',
        ),
      );
    }

    return _repository.delete(
      organizationId: trimmedOrganizationId,
      id: trimmedId,
      deletedBy: trimmedDeletedBy,
    );
  }
}
