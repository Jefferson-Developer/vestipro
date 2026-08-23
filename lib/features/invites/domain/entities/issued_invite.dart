import 'package:freezed_annotation/freezed_annotation.dart';

import 'invite.dart';

part 'issued_invite.freezed.dart';

/// The result of (re)issuing an [Invite]: the persisted [Invite] itself
/// plus the plaintext [token] the caller needs to build a shareable invite
/// link right now.
///
/// [token] is only ever available at the exact moment `createInvite`/
/// `resendInvite` succeeds — Firestore only ever stores its SHA-256 hash
/// (`Invite`'s underlying `tokenHash` field, never exposed as a domain
/// field at all). A later read of the same [Invite] (e.g. `InviteListPage`
/// re-loading the pending list) can never recover it — see
/// `functions/src/invites/invite-shared.ts`'s `generateInviteToken` docs.
@freezed
abstract class IssuedInvite with _$IssuedInvite {
  const factory IssuedInvite({required Invite invite, required String token}) =
      _IssuedInvite;
}
