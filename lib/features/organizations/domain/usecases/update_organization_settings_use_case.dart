import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/organization.dart';
import '../repositories/organization_repository.dart';
import '../value_objects/organization_settings.dart';

/// Updates an Organization's [OrganizationSettings] (currency, country,
/// default language).
///
/// This use case has no parameter that could rewrite [Organization.id] —
/// only [id] to select which Organization to update, never to change it —
/// and delegates to [OrganizationRepository.updateSettings], which is
/// equally unable to touch it.
@injectable
final class UpdateOrganizationSettingsUseCase {
  const UpdateOrganizationSettingsUseCase(this._repository);

  final OrganizationRepository _repository;

  Future<AppResult<Organization>> call({
    required String id,
    required String currency,
    required String country,
    required String defaultLanguage,
    required String updatedBy,
    List<String> requiredCustomerFields = const <String>[],
    List<String> customerAddressTypes = const <String>[],
    List<String> customerContactTypes = const <String>[],
    bool allowMultipleCollectionsPerProduct = false,
    int stockReservationExpiresInMinutes = 15,
  }) async {
    final trimmedId = id.trim();
    final trimmedUpdatedBy = updatedBy.trim();

    final fieldErrors = <String, String>{};
    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedUpdatedBy.isEmpty) {
      fieldErrors['updatedBy'] = 'UpdatedBy is required.';
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure<Organization>(
        ValidationFailure(
          'Invalid organization settings update payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_organization_update_payload',
        ),
      );
    }

    OrganizationSettings settings;
    try {
      settings = OrganizationSettings.validated(
        currency: currency,
        country: country,
        defaultLanguage: defaultLanguage,
        requiredCustomerFields: requiredCustomerFields,
        customerAddressTypes: customerAddressTypes,
        customerContactTypes: customerContactTypes,
        allowMultipleCollectionsPerProduct: allowMultipleCollectionsPerProduct,
        stockReservationExpiresInMinutes: stockReservationExpiresInMinutes,
      );
    } on ValidationException catch (exception) {
      return AppFailure<Organization>(mapAppExceptionToFailure(exception));
    }

    return _repository.updateSettings(
      id: trimmedId,
      settings: settings,
      updatedBy: trimmedUpdatedBy,
    );
  }
}
