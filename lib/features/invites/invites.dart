/// Public surface of `lib/features/invites/`: the domain contract, entities,
/// value objects and pages the rest of the app is allowed to depend on.
/// Data-layer types (`InviteDataSource`, `InviteRepositoryImpl`, DTOs) are
/// wired only through dependency injection and are never imported outside
/// this package and its tests.
library;

export 'domain/entities/invite.dart';
export 'domain/entities/issued_invite.dart';
export 'domain/repositories/invite_repository.dart';
export 'domain/role_hierarchy.dart';
export 'domain/usecases/create_invite_use_case.dart';
export 'domain/usecases/list_pending_invites_use_case.dart';
export 'domain/usecases/resend_invite_use_case.dart';
export 'domain/usecases/revoke_invite_use_case.dart';
export 'domain/validators/invite_form_validators.dart';
export 'domain/value_objects/invite_status.dart';
export 'presentation/bloc/invite_form_bloc.dart';
export 'presentation/bloc/invite_form_event.dart';
export 'presentation/bloc/invite_form_state.dart';
export 'presentation/bloc/invite_list_bloc.dart';
export 'presentation/bloc/invite_list_event.dart';
export 'presentation/bloc/invite_list_state.dart';
export 'presentation/pages/invite_list_page.dart';
export 'presentation/pages/invite_user_page.dart';
