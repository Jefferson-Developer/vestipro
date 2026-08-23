import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/errors/errors.dart';
import '../../../organizations/domain/value_objects/system_role_name.dart';
import '../../domain/entities/issued_invite.dart';

part 'invite_form_state.freezed.dart';

/// Whether [InviteFormState.assignableRoles] has finished loading yet — same
/// rationale as `OnboardingLoadStatus`.
enum InviteFormLoadStatus { loading, ready }

/// The outcome of the last [InviteFormEvent.submitted] — same rationale as
/// `OnboardingSubmissionStatus`.
enum InviteFormSubmissionStatus { idle, submitting, success, failure }

@freezed
abstract class InviteFormState with _$InviteFormState {
  const factory InviteFormState({
    @Default(InviteFormLoadStatus.loading) InviteFormLoadStatus loadStatus,
    @Default('') String organizationId,

    /// The roles the signed-in user is allowed to assign, resolved from
    /// their real Membership (`assignableRolesFor`) — never all 7 system
    /// roles unconditionally. Empty while [loadStatus] is
    /// [InviteFormLoadStatus.loading], or if their Membership could not be
    /// resolved at all (fails closed, same as [PermissionService]).
    @Default(<SystemRoleName>[]) List<SystemRoleName> assignableRoles,
    @Default('') String email,
    String? emailError,
    SystemRoleName? role,
    String? roleError,
    @Default('') String message,
    @Default(InviteFormSubmissionStatus.idle)
    InviteFormSubmissionStatus submissionStatus,

    /// Only meaningful when [submissionStatus] is
    /// [InviteFormSubmissionStatus.failure].
    Failure? failure,

    /// Only meaningful when [submissionStatus] is
    /// [InviteFormSubmissionStatus.success] — the invite just issued,
    /// including the one-time [IssuedInvite.token] `InviteUserPage` shows so
    /// it can be copied/shared right now (see [IssuedInvite]'s own docs for
    /// why it can never be retrieved again afterwards).
    IssuedInvite? issuedInvite,
  }) = _InviteFormState;
}
