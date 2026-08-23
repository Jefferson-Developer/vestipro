/// Public surface of `lib/features/users/`: the domain contract, entities
/// and pages the rest of the app is allowed to depend on. Data access is
/// deliberately not a new layer here — this feature composes
/// `organizations`' own `MembershipRepository`/`TeamRepository`, wired only
/// through dependency injection.
library;

export 'domain/entities/organization_user.dart';
export 'domain/entities/commercial_team.dart';
export 'domain/entities/customer_visibility_filter.dart';
export 'domain/entities/portfolio_assignment.dart';
export 'domain/entities/user_role_update_result.dart';
export 'domain/repositories/portfolio_assignment_repository.dart';
export 'domain/repositories/user_role_repository.dart';
export 'domain/services/portfolio_visibility_service.dart';
export 'domain/usecases/assign_portfolio_use_case.dart';
export 'domain/usecases/update_user_role_use_case.dart';
export 'domain/user_role_change_policy.dart';
export 'domain/usecases/list_commercial_teams_use_case.dart';
export 'domain/usecases/list_organization_users_use_case.dart';
export 'domain/usecases/list_portfolio_assignments_use_case.dart';
export 'presentation/bloc/assign_portfolio_bloc.dart';
export 'presentation/bloc/assign_portfolio_event.dart';
export 'presentation/bloc/assign_portfolio_state.dart';
export 'presentation/bloc/team_form_bloc.dart';
export 'presentation/bloc/team_form_event.dart';
export 'presentation/bloc/team_form_state.dart';
export 'presentation/bloc/team_list_bloc.dart';
export 'presentation/bloc/team_list_event.dart';
export 'presentation/bloc/team_list_state.dart';
export 'presentation/bloc/user_list_bloc.dart';
export 'presentation/bloc/user_list_event.dart';
export 'presentation/bloc/user_list_state.dart';
export 'presentation/bloc/user_role_edit_bloc.dart';
export 'presentation/bloc/user_role_edit_event.dart';
export 'presentation/bloc/user_role_edit_state.dart';
export 'presentation/pages/user_list_page.dart';
export 'presentation/pages/user_role_edit_page.dart';
export 'presentation/pages/assign_portfolio_page.dart';
export 'presentation/pages/team_form_page.dart';
export 'presentation/pages/team_list_page.dart';
