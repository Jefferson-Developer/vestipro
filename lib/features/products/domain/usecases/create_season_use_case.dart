import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/season.dart';
import '../repositories/season_repository.dart';

/// Creates a new `Season` vocabulary entry (TASK-066).
///
/// Season names are shared vocabulary of one Organization: two equivalent
/// entries (same trimmed name, case-insensitive) are never allowed, e.g.
/// "Verão" and "verão " both resolve to the same duplicate check.
@injectable
final class CreateSeasonUseCase {
  CreateSeasonUseCase(this._repository);

  final SeasonRepository _repository;

  Future<AppResult<Season>> call({
    required String id,
    required String organizationId,
    required String name,
    required String createdBy,
  }) async {
    final trimmedId = id.trim();
    final trimmedOrganizationId = organizationId.trim();
    final trimmedName = name.trim();
    final trimmedCreatedBy = createdBy.trim();

    final fieldErrors = <String, String>{};
    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedName.isEmpty) {
      fieldErrors['name'] = 'Informe o nome da estação.';
    }
    if (trimmedCreatedBy.isEmpty) {
      fieldErrors['createdBy'] = 'CreatedBy is required.';
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure<Season>(
        ValidationFailure(
          'Invalid season creation payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_season_create_payload',
        ),
      );
    }

    final duplicateResult = await _repository.existsByName(
      organizationId: trimmedOrganizationId,
      name: trimmedName,
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

    final now = DateTime.now().toUtc();
    final season = Season(
      id: trimmedId,
      organizationId: trimmedOrganizationId,
      name: trimmedName,
      version: 1,
      createdAt: now,
      createdBy: trimmedCreatedBy,
      updatedAt: now,
      updatedBy: trimmedCreatedBy,
    );

    return _repository.create(season: season);
  }
}
