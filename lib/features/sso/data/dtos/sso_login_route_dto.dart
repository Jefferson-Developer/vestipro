import '../../../../core/errors/errors.dart';

/// Plain-JSON shape of `resolveSsoForEmail`'s callable response (TASK-173,
/// `functions/src/sso/resolve-sso-for-email.ts`'s
/// `ResolveSsoForEmailResponse`). [found] is the only field always present —
/// every other field is `null` together, whenever [found] is `false`.
final class SsoLoginRouteDto {
  const SsoLoginRouteDto({
    required this.found,
    this.organizationId,
    this.organizationName,
    this.protocol,
    this.providerId,
  });

  factory SsoLoginRouteDto.fromJson(Map<String, dynamic> json) {
    final found = json['found'];
    if (found is! bool) {
      throw const ServerException(
        'Unexpected resolveSsoForEmail callable response shape.',
        code: 'invalid_resolve_sso_for_email_callable_response',
      );
    }

    if (!found) {
      return const SsoLoginRouteDto(found: false);
    }

    final organizationId = json['organizationId'];
    final organizationName = json['organizationName'];
    final protocol = json['protocol'];
    final providerId = json['providerId'];
    if (organizationId is! String ||
        organizationName is! String ||
        protocol is! String ||
        providerId is! String) {
      throw const ServerException(
        'Unexpected resolveSsoForEmail callable response shape.',
        code: 'invalid_resolve_sso_for_email_callable_response',
      );
    }

    return SsoLoginRouteDto(
      found: true,
      organizationId: organizationId,
      organizationName: organizationName,
      protocol: protocol,
      providerId: providerId,
    );
  }

  final bool found;
  final String? organizationId;
  final String? organizationName;
  final String? protocol;
  final String? providerId;
}
