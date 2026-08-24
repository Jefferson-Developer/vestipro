/// Public surface of `lib/features/crm/`.
library;

export 'data/mappers/crm_activity_mapper.dart';
export 'domain/entities/crm_activity.dart';
export 'domain/entities/crm_activity_page_result.dart';
export 'domain/repositories/crm_activity_repository.dart';
export 'domain/usecases/list_crm_activities_for_customer_use_case.dart';
export 'domain/usecases/list_crm_activities_for_lead_use_case.dart';
export 'domain/usecases/list_crm_activities_for_opportunity_use_case.dart';
export 'domain/usecases/register_crm_activity_use_case.dart';
export 'domain/value_objects/crm_activity_sync_status.dart';
export 'domain/value_objects/crm_activity_type.dart';
export 'presentation/widgets/crm_activity_timeline.dart';
