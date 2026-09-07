/// Public surface of `lib/features/sso/`: the domain contract, entities,
/// value objects and use case the rest of the app is allowed to depend on
/// (TASK-173, EPIC-23 — SSO corporativo SAML/OIDC).
///
/// Data-layer types (`SsoDataSource`, `SsoRepositoryImpl`, DTOs) are wired
/// only through dependency injection and are never imported outside this
/// package and its tests. This feature has no `presentation/` of its own —
/// its only UI entry point lives inside
/// `lib/features/authentication/presentation/` (the "Entrar com SSO
/// corporativo" section of `LoginPage`/`LoginForm`/`LoginBloc`), since
/// authenticating is the login screen's own concern, not a separate page.
library;

export 'domain/entities/completed_sso_login.dart';
export 'domain/entities/corporate_sso_login_result.dart';
export 'domain/entities/sso_login_route.dart';
export 'domain/repositories/sso_repository.dart';
export 'domain/usecases/sign_in_with_corporate_sso_use_case.dart';
export 'domain/value_objects/sso_protocol.dart';
