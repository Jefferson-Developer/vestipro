import 'package:freezed_annotation/freezed_annotation.dart';

import '../value_objects/sso_protocol.dart';

part 'sso_login_route.freezed.dart';

/// What `resolveSsoForEmail` resolved for a corporate e-mail (TASK-173) —
/// which organization's SSO connection it belongs to, and the exact
/// Identity Platform [providerId] `AuthRepository.signInWithFederatedProvider`
/// must use to start the federation handshake. `null` (never an instance of
/// this class) represents "no SSO configured for this e-mail" — the
/// ordinary, everyday outcome of a user typing a personal e-mail into the
/// "Entrar com SSO corporativo" field, not an exceptional server condition.
@freezed
abstract class SsoLoginRoute with _$SsoLoginRoute {
  const factory SsoLoginRoute({
    required String organizationId,
    required String organizationName,
    required SsoProtocol protocol,
    required String providerId,
  }) = _SsoLoginRoute;
}
