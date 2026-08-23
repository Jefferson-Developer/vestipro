import '../../../../core/utils/utils.dart';
import '../../../organizations/domain/value_objects/system_role_name.dart';
import '../entities/invite.dart';
import '../entities/issued_invite.dart';

/// Contract for creating, listing, resending and revoking [Invite]s scoped
/// under one Organization (TASK-039).
///
/// Every method requires [organizationId] so no query/call can be built
/// without a tenant scope by mistake — the real source of truth for
/// authorization is always the `createInvite`/`resendInvite`/`revokeInvite`
/// Cloud Functions (re-validated from the caller's real Membership), never
/// this client-side contract by itself.
abstract interface class InviteRepository {
  /// Issues a brand-new pending [Invite] for [email] to join
  /// [organizationId] as [roleName]. Only OWNER/ADMIN may succeed — enforced
  /// server-side by `createInvite`, independently of any client-side RBAC
  /// check on this side.
  Future<AppResult<IssuedInvite>> create({
    required String organizationId,
    required String email,
    required SystemRoleName roleName,
    String? message,
  });

  /// Lists every non-terminal-looking invite of [organizationId] worth
  /// showing on `InviteListPage` (pending/expired — accepted/revoked ones
  /// are historical noise for that screen), most recently created first.
  Future<AppResult<List<Invite>>> listPending(String organizationId);

  /// Reissues [inviteId]: a brand-new token/hash and `expiresAt`, on the
  /// same [Invite] document — only a `pending`/`expired` invite can be
  /// resent.
  Future<AppResult<IssuedInvite>> resend({
    required String organizationId,
    required String inviteId,
  });

  /// Revokes [inviteId] — only a `pending` invite can be revoked.
  Future<AppResult<Invite>> revoke({
    required String organizationId,
    required String inviteId,
  });
}
