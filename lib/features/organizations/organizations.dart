/// Public surface of `lib/features/organizations/`: the domain contract,
/// entities and value objects the rest of the app is allowed to depend on.
/// Data-layer types (`OrganizationDataSource`, `OrganizationRepositoryImpl`,
/// DTOs) are wired only through dependency injection and are never imported
/// outside this package and its tests.
library;

export 'domain/entities/organization.dart';
export 'domain/repositories/organization_repository.dart';
export 'domain/usecases/create_organization_use_case.dart';
export 'domain/usecases/get_organization_use_case.dart';
export 'domain/usecases/update_organization_settings_use_case.dart';
export 'domain/value_objects/organization_settings.dart';
export 'domain/value_objects/organization_status.dart';
