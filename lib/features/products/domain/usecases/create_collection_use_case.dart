import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/collection.dart';
import '../repositories/collection_repository.dart';
import '../value_objects/collection_status.dart';
import 'product_use_case_helpers.dart';

/// Creates a new `Collection` (TASK-066), always as
/// `CollectionStatus.active`.
///
/// Closing a Collection is a dedicated, separate step
/// (`CloseCollectionUseCase`), never something this use case accepts a
/// `status` argument for — the same "creation can only ever produce the
/// non-terminal state" guarantee `CreateProductUseCase` applies to
/// `ProductStatus.draft`.
@injectable
final class CreateCollectionUseCase {
  CreateCollectionUseCase(this._repository);

  final CollectionRepository _repository;

  Future<AppResult<Collection>> call({
    required String id,
    required String organizationId,
    required String name,
    String? seasonId,
    int? year,
    DateTime? startDate,
    DateTime? endDate,
    required String createdBy,
  }) async {
    final trimmedId = id.trim();
    final trimmedOrganizationId = organizationId.trim();
    final trimmedName = name.trim();
    final trimmedCreatedBy = createdBy.trim();
    final normalizedSeasonId = normalizeProductOptional(seasonId);

    final fieldErrors = _validate(
      id: trimmedId,
      organizationId: trimmedOrganizationId,
      name: trimmedName,
      actorId: trimmedCreatedBy,
      actorField: 'createdBy',
      year: year,
      startDate: startDate,
      endDate: endDate,
    );
    if (fieldErrors.isNotEmpty) {
      return AppFailure<Collection>(
        ValidationFailure(
          'Invalid collection creation payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_collection_create_payload',
        ),
      );
    }

    final now = DateTime.now().toUtc();
    final collection = Collection(
      id: trimmedId,
      organizationId: trimmedOrganizationId,
      name: trimmedName,
      seasonId: normalizedSeasonId,
      year: year,
      startDate: startDate?.toUtc(),
      endDate: endDate?.toUtc(),
      status: CollectionStatus.active,
      version: 1,
      createdAt: now,
      createdBy: trimmedCreatedBy,
      updatedAt: now,
      updatedBy: trimmedCreatedBy,
    );

    return _repository.create(collection: collection);
  }
}

/// Shared field validation for creating/updating a Collection, so both use
/// cases reject the same invalid payloads (blank id/org/name/actor, an
/// out-of-range year, an end date before the start date).
Map<String, String> _validate({
  required String id,
  required String organizationId,
  required String name,
  required String actorId,
  required String actorField,
  int? year,
  DateTime? startDate,
  DateTime? endDate,
}) {
  final fieldErrors = <String, String>{};
  if (id.isEmpty) fieldErrors['id'] = 'Id is required.';
  if (organizationId.isEmpty) {
    fieldErrors['organizationId'] = 'OrganizationId is required.';
  }
  if (name.isEmpty) {
    fieldErrors['name'] = 'Informe o nome da coleção.';
  }
  if (actorId.isEmpty) {
    fieldErrors[actorField] =
        '${actorField[0].toUpperCase()}${actorField.substring(1)} is required.';
  }
  if (year != null && (year < 2000 || year > 2100)) {
    fieldErrors['year'] = 'Informe um ano válido.';
  }
  if (startDate != null && endDate != null && endDate.isBefore(startDate)) {
    fieldErrors['endDate'] =
        'A data de término deve ser posterior à data de início.';
  }
  return fieldErrors;
}
