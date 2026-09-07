import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../domain/entities/completed_sso_login.dart';
import '../../domain/entities/sso_login_route.dart';
import '../../domain/value_objects/sso_protocol.dart';
import '../dtos/completed_sso_login_dto.dart';
import '../dtos/sso_login_route_dto.dart';

/// Maps the corporate SSO login-time DTOs (TASK-173) into their domain
/// entities.
@lazySingleton
final class SsoMapper {
  const SsoMapper();

  /// `null` when [dto] reports `found: false` — the ordinary "no SSO
  /// configured for this e-mail" outcome, never an entity with placeholder
  /// fields.
  SsoLoginRoute? toRouteEntityOrNull(SsoLoginRouteDto dto) {
    if (!dto.found) return null;
    return SsoLoginRoute(
      organizationId: dto.organizationId!,
      organizationName: dto.organizationName!,
      protocol: _protocolFromCode(dto.protocol!),
      providerId: dto.providerId!,
    );
  }

  CompletedSsoLogin toCompletedEntity(CompletedSsoLoginDto dto) {
    return CompletedSsoLogin(
      organizationId: dto.organizationId,
      organizationName: dto.organizationName,
      roleName: dto.roleName,
      provisioned: dto.provisioned,
    );
  }

  SsoProtocol _protocolFromCode(String code) {
    return switch (code) {
      'saml' => SsoProtocol.saml,
      'oidc' => SsoProtocol.oidc,
      _ => throw ValidationException(
        'Invalid SSO protocol code returned by resolveSsoForEmail.',
        code: 'invalid_sso_protocol_code',
        cause: code,
      ),
    };
  }
}
