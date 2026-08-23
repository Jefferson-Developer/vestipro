import '../../../../core/errors/errors.dart';

/// Plain-JSON shape of `validateInvite`'s callable response (TASK-040,
/// `functions/src/invites/validate-invite.ts`'s `ValidateInviteResponse`) —
/// dates never appear here at all, unlike [InviteDto], since a preview
/// carries no timestamp.
final class InvitePreviewDto {
  const InvitePreviewDto({
    required this.outcome,
    this.organizationId,
    this.organizationName,
    this.email,
    this.roleName,
  });

  factory InvitePreviewDto.fromJson(Map<String, dynamic> json) {
    final outcome = json['outcome'];
    if (outcome is! String) {
      throw const ServerException(
        'Unexpected validateInvite callable response shape.',
        code: 'invalid_validate_invite_callable_response',
      );
    }

    final organizationId = json['organizationId'];
    final organizationName = json['organizationName'];
    final email = json['email'];
    final roleName = json['roleName'];
    if ((organizationId != null && organizationId is! String) ||
        (organizationName != null && organizationName is! String) ||
        (email != null && email is! String) ||
        (roleName != null && roleName is! String)) {
      throw const ServerException(
        'Unexpected validateInvite callable response shape.',
        code: 'invalid_validate_invite_callable_response',
      );
    }

    return InvitePreviewDto(
      outcome: outcome,
      organizationId: organizationId as String?,
      organizationName: organizationName as String?,
      email: email as String?,
      roleName: roleName as String?,
    );
  }

  final String outcome;
  final String? organizationId;
  final String? organizationName;
  final String? email;
  final String? roleName;
}
