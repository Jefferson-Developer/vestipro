import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/season.dart';
import '../repositories/season_repository.dart';

/// Renames an existing `Season` (TASK-066), keeping the same duplicate-name
/// guard `CreateSeasonUseCase` applies, excluding the Season being edited.
@injectable
final class UpdateSeasonUseCase {
  UpdateSeasonUseCase(this._repository);

  final SeasonRepository _repository;

  Future<AppResult<Season>> call({
    required String organizationId,
    required String id,
    required String name,
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
    if (trimmedName.isEmpty) {
      fieldErrors['name'] = 'Informe o nome da estação.';
    }
    if (trimmedUpdatedBy.isEmpty) {
      fieldErrors['updatedBy'] = 'UpdatedBy is required.';
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure<Season>(
        ValidationFailure(
          'Invalid season update payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_season_update_payload',
        ),
      );
    }

    final existingResult = await _repository.getById(
      organizationId: trimmedOrganizationId,
      id: trimmedId,
    );
    if (existingResult is AppFailure<Season>) return existingResult;
    final existing = (existingResult as AppSuccess<Season>).value;

    final duplicateResult = await _repository.existsByName(
      organizationId: trimmedOrganizationId,
      name: trimmedName,
      excludingSeasonId: trimmedId,
    );
    if (duplicateResult is AppFailure<bool>) {
      return AppFailure<Season>(duplicateResult.failure);
    }
    if ((duplicateResult as AppSuccess<bool>).value) {
      return const AppFailure<Season>(
        ConflictFailure(
          'Já existe uma estação com esse nome nesta organização.',
          code: 'season_name_already_exists',
        ),
      );
    }

    final updated = existing.copyWith(
      name: trimmedName,
      updatedAt: DateTime.now().toUtc(),
      updatedBy: trimmedUpdatedBy,
      version: existing.version + 1,
    );

    return _repository.update(season: updated);
  }
}
