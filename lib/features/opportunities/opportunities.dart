/// Public surface of `lib/features/opportunities/`.
library;

export 'domain/entities/opportunity.dart';
export 'domain/opportunity_status_transition_rules.dart';
export 'domain/repositories/opportunity_repository.dart';
export 'domain/usecases/create_opportunity_use_case.dart';
export 'domain/usecases/mark_opportunity_lost_use_case.dart';
export 'domain/usecases/mark_opportunity_won_use_case.dart';
export 'domain/usecases/recalculate_revenue_forecast_use_case.dart';
export 'domain/usecases/update_opportunity_stage_use_case.dart';
export 'domain/value_objects/opportunity_status.dart';
export 'domain/value_objects/opportunity_sync_status.dart';
