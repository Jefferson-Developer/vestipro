/// Public surface of `lib/features/leads/`.
library;

export 'domain/entities/lead.dart';
export 'domain/entities/lead_list_filters.dart';
export 'domain/entities/lead_page_result.dart';
export 'domain/lead_status_transition_rules.dart';
export 'domain/repositories/lead_repository.dart';
export 'domain/usecases/convert_lead_to_customer_use_case.dart';
export 'domain/usecases/convert_lead_to_opportunity_use_case.dart';
export 'domain/usecases/create_lead_use_case.dart';
export 'domain/usecases/disqualify_lead_use_case.dart';
export 'domain/usecases/list_leads_use_case.dart';
export 'domain/usecases/mark_lead_contacted_use_case.dart';
export 'domain/usecases/qualify_lead_use_case.dart';
export 'domain/value_objects/lead_source.dart';
export 'domain/value_objects/lead_status.dart';
export 'domain/value_objects/lead_sync_status.dart';
export 'presentation/bloc/lead_form_bloc.dart';
export 'presentation/bloc/lead_form_event.dart';
export 'presentation/bloc/lead_form_state.dart';
export 'presentation/bloc/lead_list_bloc.dart';
export 'presentation/bloc/lead_list_event.dart';
export 'presentation/bloc/lead_list_state.dart';
export 'presentation/pages/lead_form_page.dart';
export 'presentation/pages/lead_list_page.dart';
