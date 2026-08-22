import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/organization.dart';
import '../repositories/organization_repository.dart';
import '../value_objects/organization_settings.dart';

/// Creates the Organization tenant root (`tasks.md`, section 3.1).
///
/// [id] must be generated once by the caller (e.g. the onboarding flow in
/// TASK-037) and kept stable across retries: [OrganizationRepository.create]
/// relies on that stability to stay idempotent instead of creating
/// duplicate tenants when a create request is retried after a network
/// failure.
@injectable
final class CreateOrganizationUseCase {
  const CreateOrganizationUseCase(this._repository);

  final OrganizationRepository _repository;

  Future<AppResult<Organization>> call({
    required String id,
    required String name,
    required String slug,
    required String currency,
    required String country,
    required String defaultLanguage,
    required String createdBy,
  }) async {
    final trimmedId = id.trim();
    final trimmedName = name.trim();
    final trimmedSlug = slug.trim();
    final trimmedCreatedBy = createdBy.trim();

    final fieldErrors = <String, String>{};
    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedName.isEmpty) fieldErrors['name'] = 'Name is required.';
    if (trimmedSlug.isEmpty) fieldErrors['slug'] = 'Slug is required.';
    if (trimmedCreatedBy.isEmpty) {
      fieldErrors['createdBy'] = 'CreatedBy is required.';
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure<Organization>(
        ValidationFailure(
          'Invalid organization creation payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_organization_create_payload',
        ),
      );
    }

    OrganizationSettings settings;
    try {
      settings = OrganizationSettings.validated(
        currency: currency,
        country: country,
        defaultLanguage: defaultLanguage,
      );
    } on ValidationException catch (exception) {
      return AppFailure<Organization>(mapAppExceptionToFailure(exception));
    }

    return _repository.create(
      id: trimmedId,
      name: trimmedName,
      slug: trimmedSlug,
      settings: settings,
      createdBy: trimmedCreatedBy,
    );
  }
}
