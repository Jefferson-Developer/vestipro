/// Public surface of `lib/features/crm/`.
library;

export 'data/mappers/crm_activity_mapper.dart';
export 'data/mappers/crm_task_mapper.dart';
export 'domain/entities/crm_activity.dart';
export 'domain/entities/crm_activity_page_result.dart';
export 'domain/entities/crm_task.dart';
export 'domain/repositories/crm_activity_repository.dart';
export 'domain/repositories/crm_task_repository.dart';
export 'domain/usecases/complete_crm_task_use_case.dart';
export 'domain/usecases/create_crm_task_use_case.dart';
export 'domain/usecases/list_crm_activities_for_customer_use_case.dart';
export 'domain/usecases/list_crm_activities_for_lead_use_case.dart';
export 'domain/usecases/list_crm_activities_for_opportunity_use_case.dart';
export 'domain/usecases/list_pending_tasks_for_today_use_case.dart';
export 'domain/usecases/list_pending_tasks_for_week_use_case.dart';
export 'domain/usecases/register_crm_activity_use_case.dart';
export 'domain/usecases/reschedule_crm_task_use_case.dart';
export 'domain/value_objects/crm_activity_sync_status.dart';
export 'domain/value_objects/crm_activity_type.dart';
export 'domain/value_objects/crm_task_priority.dart';
export 'domain/value_objects/crm_task_status.dart';
export 'domain/value_objects/crm_task_sync_status.dart';
export 'presentation/bloc/crm_task_list_bloc.dart';
export 'presentation/bloc/crm_task_list_event.dart';
export 'presentation/bloc/crm_task_list_state.dart';
export 'presentation/pages/crm_task_list_page.dart';
export 'presentation/widgets/crm_activity_timeline.dart';
