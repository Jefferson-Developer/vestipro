import '../../../../core/errors/errors.dart';

/// Plain-JSON shape of `acceptInvite`'s callable response (TASK-040,
/// `functions/src/invites/accept-invite.ts`'s `AcceptInviteResponse`).
final class AcceptedInviteDto {
  const AcceptedInviteDto({
    required this.organizationId,
    required this.organizationName,
    required this.roleName,
  });

  factory AcceptedInviteDto.fromJson(Map<String, dynamic> json) {
    final organizationId = json['organizationId'];
    final organizationName = json['organizationName'];
    final roleName = json['roleName'];

    if (organizationId is! String ||
        organizationName is! String ||
        roleName is! String) {
      throw const ServerException(
        'Unexpected acceptInvite callable response shape.',
        code: 'invalid_accept_invite_callable_response',
      );
    }

    return AcceptedInviteDto(
      organizationId: organizationId,
      organizationName: organizationName,
      roleName: roleName,
    );
  }

  final String organizationId;
  final String organizationName;
  final String roleName;
}
