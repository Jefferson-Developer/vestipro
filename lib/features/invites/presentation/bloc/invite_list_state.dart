import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/errors/errors.dart';
import '../../domain/entities/invite.dart';
import '../../domain/entities/issued_invite.dart';

part 'invite_list_state.freezed.dart';

/// The load outcome of `InviteListPage`'s pending-invites list — same
/// three-way shape as most list screens in this app (loading/ready never
/// hides a partial failure behind a silently-empty list).
enum InviteListLoadStatus { loading, ready, failure }

@freezed
abstract class InviteListState with _$InviteListState {
  const factory InviteListState({
    @Default(InviteListLoadStatus.loading) InviteListLoadStatus loadStatus,
    @Default('') String organizationId,
    @Default(<Invite>[]) List<Invite> invites,

    /// Only meaningful when [loadStatus] is [InviteListLoadStatus.failure].
    Failure? loadFailure,

    /// The id of the invite currently being resent/revoked, so its row can
    /// show a busy state while every other row stays interactive. `null`
    /// when no resend/revoke is in flight.
    String? processingInviteId,

    /// The result of the last successful resend — `InviteListPage` shows
    /// its one-time [IssuedInvite.token] right after (see [IssuedInvite]'s
    /// own docs for why it can never be retrieved again afterwards). Reset
    /// to `null` on the next list load/resend/revoke.
    IssuedInvite? lastResendResult,

    /// A resend/revoke that failed — shown once (e.g. a snackbar), then
    /// expected to be cleared by the caller.
    Failure? actionFailure,
  }) = _InviteListState;
}
