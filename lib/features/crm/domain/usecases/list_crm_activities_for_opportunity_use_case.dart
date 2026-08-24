import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/crm_activity_page_result.dart';
import '../repositories/crm_activity_repository.dart';

@injectable
final class ListCrmActivitiesForOpportunityUseCase {
  ListCrmActivitiesForOpportunityUseCase(this._repository);

  final CrmActivityRepository _repository;

  Future<AppResult<CrmActivityPageResult>> call({
    required String organizationId,
    required String opportunityId,
    int limit = 20,
    String? cursor,
    bool ascending = false,
  }) {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedOpportunityId = opportunityId.trim();
    if (trimmedOrganizationId.isEmpty || trimmedOpportunityId.isEmpty) {
      return Future.value(
        const AppFailure<CrmActivityPageResult>(
          ValidationFailure(
            'Invalid CRM activity opportunity timeline payload.',
            fieldErrors: <String, String>{
              'organizationId': 'OrganizationId is required.',
              'opportunityId': 'OpportunityId is required.',
            },
            code: 'invalid_crm_activity_opportunity_timeline_payload',
          ),
        ),
      );
    }
    return _repository.listForOpportunity(
      organizationId: trimmedOrganizationId,
      opportunityId: trimmedOpportunityId,
      limit: limit,
      cursor: cursor,
      ascending: ascending,
    );
  }
}
