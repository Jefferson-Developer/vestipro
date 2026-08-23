import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/errors/errors.dart';
import '../../../organizations/domain/value_objects/system_role_name.dart';
import '../../domain/value_objects/invite_acceptance_outcome.dart';

part 'accept_invite_state.freezed.dart';

/// Whether [AcceptInviteState.outcome] has finished loading yet.
enum AcceptInviteValidationStatus {
  /// `validateInvite` is in flight — `AcceptInvitePage` shows a spinner,
  /// never any option.
  loading,

  /// `validateInvite` answered — [AcceptInviteState.outcome] is now
  /// meaningful, whichever value it is (including a non-`valid` one, which
  /// `AcceptInvitePage` renders as a specific, clear message).
  ready,

  /// `validateInvite` itself could not be reached/answered (network,
  /// server error) — distinct from `ready` with a non-`valid` outcome:
  /// this is a genuine technical failure ([AcceptInviteState.failure]),
  /// not an expected business state of the invite.
  error,
}

/// The outcome of the last [AcceptInviteEvent.confirmed] — same rationale as
/// `SignUpSubmissionStatus`/`OnboardingSubmissionStatus`.
enum AcceptInviteAcceptanceStatus { idle, submitting, success, failure }

@freezed
abstract class AcceptInviteState with _$AcceptInviteState {
  const factory AcceptInviteState({
    @Default('') String token,
    @Default(AcceptInviteValidationStatus.loading)
    AcceptInviteValidationStatus validationStatus,

    /// Only meaningful once [validationStatus] is
    /// [AcceptInviteValidationStatus.ready].
    @Default(InviteAcceptanceOutcome.notFound) InviteAcceptanceOutcome outcome,
    String? organizationId,
    String? organizationName,
    String? invitedEmail,
    SystemRoleName? roleName,

    /// Whether someone is already signed in, resolved once, right when
    /// [validationStatus] becomes [AcceptInviteValidationStatus.ready] with
    /// a [InviteAcceptanceOutcome.valid] outcome. `false` after
    /// [AcceptInviteEvent.signOutRequested] succeeds.
    @Default(false) bool hasActiveSession,

    /// Only meaningful while [hasActiveSession] is `true`: whether the
    /// signed-in user's e-mail diverges from [invitedEmail]
    /// (case-insensitively) — the documented TASK-040 rule is to **block**
    /// this case client-side (steering the user to sign out) on top of the
    /// server-side `permission-denied` `acceptInvite` would return anyway.
    @Default(false) bool sessionEmailMismatch,
    @Default(AcceptInviteAcceptanceStatus.idle)
    AcceptInviteAcceptanceStatus acceptanceStatus,

    /// Only meaningful when [acceptanceStatus] is
    /// [AcceptInviteAcceptanceStatus.success] — where `AcceptInvitePage`
    /// navigates to next.
    String? acceptedOrganizationId,

    /// Meaningful when [validationStatus] is
    /// [AcceptInviteValidationStatus.error] or [acceptanceStatus] is
    /// [AcceptInviteAcceptanceStatus.failure].
    Failure? failure,
  }) = _AcceptInviteState;
}
