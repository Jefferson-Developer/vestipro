import '../dtos/invite_dto.dart';

/// An [InviteDto] together with the plaintext invite token, returned only
/// by [InviteDataSource.create]/[InviteDataSource.resend] — see
/// `IssuedInvite`'s own docs for why the token is never available again
/// afterwards.
typedef IssuedInviteDto = ({InviteDto invite, String token});

/// Contract for reading/writing `organizations/{organizationId}/invites`
/// (TASK-039). [create]/[resend]/[revoke] are always Cloud Function calls
/// (Admin SDK is the only writer of this collection — see
/// `firestore.rules`), never a direct Firestore write; [listPending] reads
/// Firestore directly, gated by the same `user.invite` capability the
/// Cloud Functions themselves re-validate.
abstract interface class InviteDataSource {
  Future<IssuedInviteDto> create({
    required String organizationId,
    required String email,
    required String roleName,
    String? message,
  });

  Future<List<InviteDto>> listPending(String organizationId);

  Future<IssuedInviteDto> resend({
    required String organizationId,
    required String inviteId,
  });

  Future<InviteDto> revoke({
    required String organizationId,
    required String inviteId,
  });
}
