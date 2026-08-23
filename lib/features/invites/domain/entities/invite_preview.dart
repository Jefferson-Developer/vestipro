import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../organizations/domain/value_objects/system_role_name.dart';
import '../value_objects/invite_acceptance_outcome.dart';

part 'invite_preview.freezed.dart';

/// What `AcceptInvitePage` learns about a token from `validateInvite`
/// (TASK-040), before ever offering the user an option.
///
/// [organizationName]/[email]/[roleName] are populated whenever the token
/// matched some `Invite` document, regardless of [outcome] — even a
/// revoked/expired/already-accepted invite is shown with its original
/// context (e.g. "Este convite para Grupo Fashion XPTO já foi utilizado"),
/// same "clear message, never a raw error" requirement `tasks.md`/TASK-040
/// asks for. They are all `null` only when [outcome] is
/// [InviteAcceptanceOutcome.notFound] — there is no `Invite` to describe.
@freezed
abstract class InvitePreview with _$InvitePreview {
  const factory InvitePreview({
    required InviteAcceptanceOutcome outcome,
    String? organizationId,
    String? organizationName,
    String? email,
    SystemRoleName? roleName,
  }) = _InvitePreview;
}
