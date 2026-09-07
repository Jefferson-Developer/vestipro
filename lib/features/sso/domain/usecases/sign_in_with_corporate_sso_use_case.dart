import 'package:injectable/injectable.dart';

import '../../../../core/auth/domain/entities/session_user.dart';
import '../../../../core/auth/domain/repositories/auth_repository.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/completed_sso_login.dart';
import '../entities/corporate_sso_login_result.dart';
import '../entities/sso_login_route.dart';
import '../repositories/sso_repository.dart';
import '../value_objects/sso_protocol.dart';

/// Orchestrates VestiPro's corporate SSO login flow end to end (TASK-173),
/// so `LoginBloc` never has to sequence the three separate steps itself:
///
/// 1. [SsoRepository.resolveConnectionForEmail] — which organization's
///    connection (if any) [email] routes to, and its Identity Platform
///    [SsoLoginRoute.providerId].
/// 2. [AuthRepository.signInWithFederatedProvider] — the actual SAML/OIDC
///    federation handshake against that `providerId`.
/// 3. [SsoRepository.completeSsoLogin] — the just-in-time
///    provisioning/RBAC decision, now that the caller is authenticated.
///
/// Fails fast (without ever touching [AuthRepository]) when step 1 finds no
/// connection at all — a corporate SSO login is never attempted against a
/// provider that does not exist, unlike `signInWithEmailAndPassword`, which
/// always reaches Firebase Auth to let it decide "wrong e-mail/senha" itself.
@injectable
final class SignInWithCorporateSsoUseCase {
  const SignInWithCorporateSsoUseCase(
    this._ssoRepository,
    this._authRepository,
  );

  final SsoRepository _ssoRepository;
  final AuthRepository _authRepository;

  Future<AppResult<CorporateSsoLoginResult>> call({
    required String email,
  }) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      return AppFailure<CorporateSsoLoginResult>(
        const ValidationFailure(
          'Informe seu e-mail corporativo.',
          code: 'sso_email_required',
        ),
      );
    }

    final routeResult = await _ssoRepository.resolveConnectionForEmail(
      email: trimmedEmail,
    );
    final SsoLoginRoute? route;
    switch (routeResult) {
      case AppSuccess<SsoLoginRoute?>(value: final value):
        route = value;
      case AppFailure<SsoLoginRoute?>(failure: final failure):
        return AppFailure<CorporateSsoLoginResult>(failure);
    }

    if (route == null) {
      return AppFailure<CorporateSsoLoginResult>(
        const NotFoundFailure(
          'Nenhum provedor de SSO corporativo está configurado para este e-mail.',
          code: 'sso_connection_not_found',
        ),
      );
    }

    final signInResult = await _authRepository.signInWithFederatedProvider(
      providerId: route.providerId,
      isSaml: route.protocol == SsoProtocol.saml,
    );
    final SessionUser sessionUser;
    switch (signInResult) {
      case AppSuccess<SessionUser>(value: final value):
        sessionUser = value;
      case AppFailure<SessionUser>(failure: final failure):
        return AppFailure<CorporateSsoLoginResult>(failure);
    }

    final completionResult = await _ssoRepository.completeSsoLogin();
    final CompletedSsoLogin completion;
    switch (completionResult) {
      case AppSuccess<CompletedSsoLogin>(value: final value):
        completion = value;
      case AppFailure<CompletedSsoLogin>(failure: final failure):
        return AppFailure<CorporateSsoLoginResult>(failure);
    }

    return AppSuccess<CorporateSsoLoginResult>(
      CorporateSsoLoginResult(
        sessionUser: sessionUser,
        organizationId: completion.organizationId,
        organizationName: completion.organizationName,
      ),
    );
  }
}
