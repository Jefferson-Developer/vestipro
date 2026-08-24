import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/crm_activity_page_result.dart';
import '../repositories/crm_activity_repository.dart';

@injectable
final class ListCrmActivitiesForLeadUseCase {
  ListCrmActivitiesForLeadUseCase(this._repository);

  final CrmActivityRepository _repository;

  Future<AppResult<CrmActivityPageResult>> call({
    required String organizationId,
    required String leadId,
    int limit = 20,
    String? cursor,
    bool ascending = false,
  }) {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedLeadId = leadId.trim();
    if (trimmedOrganizationId.isEmpty || trimmedLeadId.isEmpty) {
      return Future.value(
        const AppFailure<CrmActivityPageResult>(
          ValidationFailure(
            'Invalid CRM activity lead timeline payload.',
            fieldErrors: <String, String>{
              'organizationId': 'OrganizationId is required.',
              'leadId': 'LeadId is required.',
            },
            code: 'invalid_crm_activity_lead_timeline_payload',
          ),
        ),
      );
    }
    return _repository.listForLead(
      organizationId: trimmedOrganizationId,
      leadId: trimmedLeadId,
      limit: limit,
      cursor: cursor,
      ascending: ascending,
    );
  }
}
