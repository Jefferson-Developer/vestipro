/// Public surface of `lib/features/organizations/`: the domain contract,
/// entities and value objects the rest of the app is allowed to depend on.
/// Data-layer types (`OrganizationDataSource`, `OrganizationRepositoryImpl`,
/// DTOs) are wired only through dependency injection and are never imported
/// outside this package and its tests.
library;

export 'domain/entities/branch.dart';
export 'domain/entities/company.dart';
export 'domain/entities/membership.dart';
export 'domain/entities/organization.dart';
export 'domain/entities/role.dart';
export 'domain/entities/team.dart';
export 'domain/repositories/branch_repository.dart';
export 'domain/repositories/company_repository.dart';
export 'domain/repositories/membership_repository.dart';
export 'domain/repositories/organization_repository.dart';
export 'domain/repositories/role_repository.dart';
export 'domain/repositories/team_repository.dart';
export 'domain/usecases/add_user_to_team_use_case.dart';
export 'domain/usecases/assign_role_to_user_use_case.dart';
export 'domain/usecases/create_branch_use_case.dart';
export 'domain/usecases/create_company_use_case.dart';
export 'domain/usecases/create_organization_use_case.dart';
export 'domain/usecases/create_team_use_case.dart';
export 'domain/usecases/ensure_system_roles_use_case.dart';
export 'domain/usecases/get_organization_use_case.dart';
export 'domain/usecases/get_user_membership_use_case.dart';
export 'domain/usecases/list_branches_by_company_use_case.dart';
export 'domain/usecases/list_companies_use_case.dart';
export 'domain/usecases/update_branch_use_case.dart';
export 'domain/usecases/update_company_use_case.dart';
export 'domain/usecases/update_organization_settings_use_case.dart';
export 'domain/value_objects/branch_address.dart';
export 'domain/value_objects/branch_status.dart';
export 'domain/value_objects/branch_type.dart';
export 'domain/value_objects/company_status.dart';
export 'domain/value_objects/membership_status.dart';
export 'domain/value_objects/organization_settings.dart';
export 'domain/value_objects/organization_status.dart';
export 'domain/value_objects/system_role_name.dart';
