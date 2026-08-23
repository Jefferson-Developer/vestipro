import 'package:freezed_annotation/freezed_annotation.dart';

part 'invite_list_event.freezed.dart';

@freezed
sealed class InviteListEvent with _$InviteListEvent {
  /// Loads the pending/expired invites of [organizationId] — dispatched
  /// once, right when `InviteListPage` is built.
  const factory InviteListEvent.started(String organizationId) =
      InviteListStarted;

  /// Reloads the same list, e.g. from a pull-to-refresh or a retry button.
  const factory InviteListEvent.refreshRequested() = InviteListRefreshRequested;

  /// Reissues [inviteId] (`ResendInviteUseCase`): a brand-new token/hash and
  /// `expiresAt`, invalidating whatever was issued before.
  const factory InviteListEvent.resendRequested(String inviteId) =
      InviteListResendRequested;

  /// Revokes [inviteId] (`RevokeInviteUseCase`) — only a pending invite can
  /// actually be revoked, enforced server-side.
  const factory InviteListEvent.revokeRequested(String inviteId) =
      InviteListRevokeRequested;
}
