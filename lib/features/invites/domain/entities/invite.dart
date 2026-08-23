import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../organizations/domain/value_objects/system_role_name.dart';
import '../value_objects/invite_status.dart';

part 'invite.freezed.dart';

/// A pending (or resolved) invitation for someone to join an [Organization]
/// with a given role (TASK-039, `tasks.md` seção 3.1/EPIC-04).
///
/// Created, resent and revoked exclusively by the `createInvite`/
/// `resendInvite`/`revokeInvite` Cloud Functions
/// (`functions/src/invites/`) — no client code ever writes an [Invite] to
/// Firestore directly (`firestore.rules`' `invites` subcollection denies
/// `create`/`update`/`delete` unconditionally). Deliberately never carries
/// the invite token itself, plaintext or hashed: that is returned only
/// once, alongside a freshly (re)issued [Invite], as [IssuedInvite.token].
@freezed
abstract class Invite with _$Invite {
  const factory Invite({
    required String id,
    required String organizationId,
    required String email,
    required SystemRoleName roleName,
    required InviteStatus status,
    required String invitedByUserId,
    required String invitedByName,
    String? message,
    required DateTime expiresAt,
    required DateTime createdAt,
    required String createdBy,
    required DateTime updatedAt,
    required String updatedBy,
  }) = _Invite;
}
