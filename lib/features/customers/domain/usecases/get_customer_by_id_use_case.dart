import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/customer.dart';
import '../repositories/customer_repository.dart';

@injectable
final class GetCustomerByIdUseCase {
  GetCustomerByIdUseCase(this._repository);

  final CustomerRepository _repository;

  Future<AppResult<Customer>> call({
    required String organizationId,
    required String id,
  }) {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedId = id.trim();

    final fieldErrors = <String, String>{};
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';

    if (fieldErrors.isNotEmpty) {
      return Future<AppResult<Customer>>.value(
        AppFailure<Customer>(
          ValidationFailure(
            'Invalid customer lookup payload.',
            fieldErrors: fieldErrors,
            code: 'invalid_customer_lookup_payload',
          ),
        ),
      );
    }

    return _repository.getById(
      organizationId: trimmedOrganizationId,
      id: trimmedId,
    );
  }
}
