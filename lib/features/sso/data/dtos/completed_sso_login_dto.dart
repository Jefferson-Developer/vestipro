import '../../../../core/errors/errors.dart';

/// Plain-JSON shape of `completeSsoLogin`'s callable response (TASK-173,
/// `functions/src/sso/complete-sso-login.ts`'s `CompleteSsoLoginResponse`).
final class CompletedSsoLoginDto {
  const CompletedSsoLoginDto({
    required this.organizationId,
    required this.organizationName,
    required this.roleName,
    required this.provisioned,
  });

  factory CompletedSsoLoginDto.fromJson(Map<String, dynamic> json) {
    final organizationId = json['organizationId'];
    final organizationName = json['organizationName'];
    final roleName = json['roleName'];
    final provisioned = json['provisioned'];

    if (organizationId is! String ||
        organizationName is! String ||
        roleName is! String ||
        provisioned is! bool) {
      throw const ServerException(
        'Unexpected completeSsoLogin callable response shape.',
        code: 'invalid_complete_sso_login_callable_response',
      );
    }

    return CompletedSsoLoginDto(
      organizationId: organizationId,
      organizationName: organizationName,
      roleName: roleName,
      provisioned: provisioned,
    );
  }

  final String organizationId;
  final String organizationName;
  final String roleName;
  final bool provisioned;
}
