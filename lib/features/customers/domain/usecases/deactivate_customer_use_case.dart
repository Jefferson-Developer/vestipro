import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/customer.dart';
import '../repositories/customer_repository.dart';

final class DeactivateCustomerUseCase {
  DeactivateCustomerUseCase(this._repository);

  final CustomerRepository _repository;

  Future<AppResult<Customer>> call({
    required String organizationId,
    required String id,
    required String updatedBy,
  }) {
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
      return Future<AppResult<Customer>>.value(
        AppFailure<Customer>(
          ValidationFailure(
            'Invalid customer deactivation payload.',
            fieldErrors: fieldErrors,
            code: 'invalid_customer_deactivate_payload',
          ),
        ),
      );
    }

    return _repository.deactivate(
      organizationId: trimmedOrganizationId,
      id: trimmedId,
      updatedBy: trimmedUpdatedBy,
    );
  }
}
