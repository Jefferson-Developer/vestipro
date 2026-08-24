import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/crm_activity_page_result.dart';
import '../repositories/crm_activity_repository.dart';

@injectable
final class ListCrmActivitiesForCustomerUseCase {
  ListCrmActivitiesForCustomerUseCase(this._repository);

  final CrmActivityRepository _repository;

  Future<AppResult<CrmActivityPageResult>> call({
    required String organizationId,
    required String customerId,
    int limit = 20,
    String? cursor,
    bool ascending = false,
  }) {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedCustomerId = customerId.trim();
    if (trimmedOrganizationId.isEmpty || trimmedCustomerId.isEmpty) {
      return Future.value(
        const AppFailure<CrmActivityPageResult>(
          ValidationFailure(
            'Invalid CRM activity customer timeline payload.',
            fieldErrors: <String, String>{
              'organizationId': 'OrganizationId is required.',
              'customerId': 'CustomerId is required.',
            },
            code: 'invalid_crm_activity_customer_timeline_payload',
          ),
        ),
      );
    }
    return _repository.listForCustomer(
      organizationId: trimmedOrganizationId,
      customerId: trimmedCustomerId,
      limit: limit,
      cursor: cursor,
      ascending: ascending,
    );
  }
}
