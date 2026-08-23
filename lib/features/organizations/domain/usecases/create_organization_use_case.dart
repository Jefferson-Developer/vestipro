import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/organization.dart';
import '../repositories/organization_repository.dart';
import '../value_objects/organization_settings.dart';

/// Creates the Organization tenant root for the onboarding flow (`tasks.md`,
/// section 3.1) — the first Organization of [createdBy], who becomes its
/// `OWNER` (TASK-037).
///
/// [id] should be generated once by the caller and kept stable across
/// retries, the same way any other idempotency key is used in this
/// codebase, but [OrganizationRepository.create] does not actually depend
/// on that: it calls the `createOrganization` Cloud Function, whose own
/// idempotency is tracked server-side per [createdBy] (one Organization per
/// creator), not per [id] — so even a retry that generates a *different*
/// [id] after losing local state still cannot create a second Organization
/// for the same user.
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

    /// The Organization's fashion segment (`OrganizationSegment.code`),
    /// collected by the onboarding wizard (TASK-038). Optional — and never
    /// validated here — for the same reason it is optional on
    /// [OrganizationSettings] itself: see that type's own doc.
    String? segment,
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
        segment: segment,
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
