import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../organizations/domain/value_objects/system_role_name.dart';

part 'invite_form_event.freezed.dart';

@freezed
sealed class InviteFormEvent with _$InviteFormEvent {
  /// Loads the roles the signed-in user is allowed to assign inside
  /// [organizationId] (`assignableRolesFor`, resolved from their real
  /// Membership) — dispatched once, right when `InviteUserPage` is built.
  const factory InviteFormEvent.started(String organizationId) =
      InviteFormStarted;

  const factory InviteFormEvent.emailChanged(String email) =
      InviteFormEmailChanged;

  const factory InviteFormEvent.roleSelected(SystemRoleName role) =
      InviteFormRoleSelected;

  const factory InviteFormEvent.messageChanged(String message) =
      InviteFormMessageChanged;

  /// Validates the form and, if it passes, issues the invite via
  /// [CreateInviteUseCase]. Real authorization always happens server-side
  /// (`createInvite`), regardless of what this client-side validation
  /// allowed through.
  const factory InviteFormEvent.submitted() = InviteFormSubmitted;
}
