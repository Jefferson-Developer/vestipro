/// Public surface of `lib/core/auth/`: the domain contract, entities and
/// value objects the rest of the app is allowed to depend on. Data-layer
/// types (`AuthDataSource`, `AuthRepositoryImpl`, DTOs) are wired only
/// through dependency injection and are never imported outside this
/// package and its tests.
library;

export 'domain/entities/session_user.dart';
export 'domain/repositories/auth_repository.dart';
export 'domain/value_objects/auth_provider_type.dart';
