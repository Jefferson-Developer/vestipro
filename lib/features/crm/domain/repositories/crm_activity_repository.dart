import '../../../../core/utils/utils.dart';
import '../entities/crm_activity.dart';
import '../entities/crm_activity_page_result.dart';

abstract interface class CrmActivityRepository {
  Future<AppResult<CrmActivity>> create({required CrmActivity activity});

  Future<AppResult<CrmActivityPageResult>> listForCustomer({
    required String organizationId,
    required String customerId,
    int limit = 20,
    String? cursor,
    bool ascending = false,
  });

  Future<AppResult<CrmActivityPageResult>> listForLead({
    required String organizationId,
    required String leadId,
    int limit = 20,
    String? cursor,
    bool ascending = false,
  });

  Future<AppResult<CrmActivityPageResult>> listForOpportunity({
    required String organizationId,
    required String opportunityId,
    int limit = 20,
    String? cursor,
    bool ascending = false,
  });
}
