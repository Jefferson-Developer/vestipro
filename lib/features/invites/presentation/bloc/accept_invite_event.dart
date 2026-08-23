import 'package:freezed_annotation/freezed_annotation.dart';

part 'accept_invite_event.freezed.dart';

@freezed
sealed class AcceptInviteEvent with _$AcceptInviteEvent {
  /// Validates [token] against `validateInvite`, dispatched once when
  /// `AcceptInvitePage` is built.
  const factory AcceptInviteEvent.started(String token) = AcceptInviteStarted;

  /// Confirms the invite: dispatched either by the "Aceitar convite"
  /// button (already-authenticated, matching e-mail) or by the embedded
  /// `SignUpBloc`'s own success (brand-new account, e-mail locked to the
  /// invite's) — both reach the exact same server call, since by the time
  /// either happens the caller is authenticated as exactly the invite's
  /// e-mail.
  const factory AcceptInviteEvent.confirmed() = AcceptInviteConfirmed;

  /// Signs the current (e-mail-mismatched) user out so a brand-new account
  /// matching the invite's e-mail can be created instead.
  const factory AcceptInviteEvent.signOutRequested() =
      AcceptInviteSignOutRequested;
}
