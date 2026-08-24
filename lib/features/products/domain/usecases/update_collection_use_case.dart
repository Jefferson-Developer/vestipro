import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/collection.dart';
import '../repositories/collection_repository.dart';
import 'product_use_case_helpers.dart';

/// Updates a `Collection`'s descriptive fields (name, season, year, date
/// range) (TASK-066). Never touches `Collection.status` — closing/reopening
/// a Collection is exclusively `CloseCollectionUseCase`'s responsibility, so
/// a routine edit can never accidentally reopen/close it.
@injectable
final class UpdateCollectionUseCase {
  UpdateCollectionUseCase(this._repository);

  final CollectionRepository _repository;

  Future<AppResult<Collection>> call({
    required String organizationId,
    required String id,
    required String name,
    String? seasonId,
    int? year,
    DateTime? startDate,
    DateTime? endDate,
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
      fieldErrors['name'] = 'Informe o nome da coleção.';
    }
    if (trimmedUpdatedBy.isEmpty) {
      fieldErrors['updatedBy'] = 'UpdatedBy is required.';
    }
    if (year != null && (year < 2000 || year > 2100)) {
      fieldErrors['year'] = 'Informe um ano válido.';
    }
    if (startDate != null && endDate != null && endDate.isBefore(startDate)) {
      fieldErrors['endDate'] =
          'A data de término deve ser posterior à data de início.';
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure<Collection>(
        ValidationFailure(
          'Invalid collection update payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_collection_update_payload',
        ),
      );
    }

    final existingResult = await _repository.getById(
      organizationId: trimmedOrganizationId,
      id: trimmedId,
    );
    if (existingResult is AppFailure<Collection>) return existingResult;
    final existing = (existingResult as AppSuccess<Collection>).value;

    final updated = existing.copyWith(
      name: trimmedName,
      seasonId: normalizeProductOptional(seasonId),
      year: year,
      startDate: startDate?.toUtc(),
      endDate: endDate?.toUtc(),
      updatedAt: DateTime.now().toUtc(),
      updatedBy: trimmedUpdatedBy,
      version: existing.version + 1,
    );

    return _repository.update(collection: updated);
  }
}
