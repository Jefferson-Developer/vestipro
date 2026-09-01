/// Public surface of `lib/features/targets/`.
library;

export 'data/dtos/target_dto.dart';
export 'data/mappers/target_mapper.dart';
export 'data/repositories/drift_target_achievement_repository.dart';
export 'data/repositories/shared_preferences_target_repository.dart';
export 'domain/entities/target.dart';
export 'domain/entities/target_achievement_snapshot.dart';
export 'domain/entities/target_progress_view_model.dart';
export 'domain/entities/target_visibility_filter.dart';
export 'domain/repositories/target_achievement_repository.dart';
export 'domain/repositories/target_repository.dart';
export 'domain/services/target_visibility_service.dart';
export 'domain/target_period_overlap.dart';
export 'domain/usecases/create_target_use_case.dart';
export 'domain/usecases/target_use_case_helpers.dart';
export 'domain/usecases/update_target_use_case.dart';
export 'domain/value_objects/target_dimension_type.dart';
export 'domain/value_objects/target_metric_type.dart';
export 'domain/value_objects/target_period_granularity.dart';
export 'domain/value_objects/target_status.dart';
export 'domain/value_objects/target_sync_status.dart';
export 'presentation/cubit/target_dashboard_cubit.dart';
export 'presentation/cubit/target_dashboard_state.dart';
export 'presentation/cubit/target_form_cubit.dart';
export 'presentation/cubit/target_form_state.dart';
export 'presentation/pages/target_dashboard_page.dart';
export 'presentation/pages/target_form_page.dart';
