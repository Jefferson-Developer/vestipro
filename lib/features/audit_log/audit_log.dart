/// Public surface of `lib/features/audit_log/`: the domain contract,
/// entities and value objects the rest of the app is allowed to depend on.
/// Data-layer types (`AuditLogDataSource`, `AuditLogRepositoryImpl`, DTOs)
/// are wired only through dependency injection and are never imported
/// outside this package and its tests.
library;

export 'domain/entities/audit_log_entry.dart';
export 'domain/entities/audit_log_entry_page.dart';
export 'domain/repositories/audit_log_repository.dart';
export 'domain/usecases/list_audit_log_entries_use_case.dart';
export 'domain/usecases/record_audit_log_use_case.dart';
export 'domain/value_objects/audit_action.dart';
export 'presentation/bloc/audit_log_action_filter.dart';
export 'presentation/bloc/audit_log_bloc.dart';
export 'presentation/bloc/audit_log_event.dart';
export 'presentation/bloc/audit_log_state.dart';
export 'presentation/pages/audit_log_page.dart';
export 'presentation/presenters/audit_log_presenter.dart';
