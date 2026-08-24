/// Public surface of `lib/features/leads/`.
library;

export 'domain/entities/lead.dart';
export 'domain/lead_status_transition_rules.dart';
export 'domain/repositories/lead_repository.dart';
export 'domain/usecases/convert_lead_to_customer_use_case.dart';
export 'domain/usecases/convert_lead_to_opportunity_use_case.dart';
export 'domain/usecases/create_lead_use_case.dart';
export 'domain/usecases/disqualify_lead_use_case.dart';
export 'domain/usecases/mark_lead_contacted_use_case.dart';
export 'domain/usecases/qualify_lead_use_case.dart';
export 'domain/value_objects/lead_source.dart';
export 'domain/value_objects/lead_status.dart';
export 'domain/value_objects/lead_sync_status.dart';
