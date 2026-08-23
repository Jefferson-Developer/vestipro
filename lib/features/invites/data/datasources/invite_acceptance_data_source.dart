import '../dtos/accepted_invite_dto.dart';
import '../dtos/invite_preview_dto.dart';

/// Contract for the two `Invite`-acceptance Cloud Functions (TASK-040):
/// `validateInvite` (no authentication required) and `acceptInvite`
/// (requires one). Always Cloud Function calls — no Firestore read/write
/// of `invites`/`members` ever happens directly here (see
/// `firestore.rules`: `invites.create/update/delete` are `if false`
/// unconditionally; `acceptInvite` is the Admin SDK's only writer of a
/// Membership born from an invite).
abstract interface class InviteAcceptanceDataSource {
  Future<InvitePreviewDto> validate({required String token});

  Future<AcceptedInviteDto> accept({required String token});
}
