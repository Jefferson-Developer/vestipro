import '../../../../core/utils/utils.dart';
import '../entities/accepted_invite.dart';
import '../entities/invite_preview.dart';

/// Contract for the token-driven invite acceptance flow (TASK-040):
/// validating a token nobody needs to be signed in for, then accepting it
/// once authenticated.
///
/// Deliberately a separate contract from [InviteRepository] (management of
/// invites by an already-authenticated OWNER/ADMIN, always scoped by
/// `organizationId`): here the caller only ever has a [token] — the
/// `organizationId` is not known ahead of time, it is *resolved* by
/// [validate]/[accept] from whatever `Invite` the token matches. Mixing the
/// two into one contract would break [InviteRepository]'s own invariant
/// ("no query/call can be built without a tenant scope by mistake").
abstract interface class InviteAcceptanceRepository {
  /// Reports what [token] currently resolves to — never throws for an
  /// expected business outcome (unknown/expired/accepted/revoked token);
  /// only an [AppFailure] represents a genuine technical failure (network,
  /// server error). The real authorization decision is always [accept]'s
  /// (ultimately `acceptInvite`'s), never this validation by itself.
  Future<AppResult<InvitePreview>> validate({required String token});

  /// Accepts [token]: creates/updates the caller's Membership with the
  /// invite's role and marks the `Invite` accepted. Requires the caller to
  /// be authenticated — enforced server-side by `acceptInvite`,
  /// independently of anything this client-side call assumes.
  Future<AppResult<AcceptedInvite>> accept({required String token});
}
