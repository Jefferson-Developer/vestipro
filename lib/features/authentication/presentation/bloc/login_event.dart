import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_event.freezed.dart';

@freezed
sealed class LoginEvent with _$LoginEvent {
  const factory LoginEvent.emailChanged(String email) = LoginEmailChanged;

  const factory LoginEvent.passwordChanged(String password) =
      LoginPasswordChanged;

  const factory LoginEvent.passwordVisibilityToggled() =
      LoginPasswordVisibilityToggled;

  const factory LoginEvent.submitted() = LoginSubmitted;

  /// Edits the "e-mail corporativo" field of the "Entrar com SSO
  /// corporativo" section (TASK-173) — kept entirely separate from
  /// [LoginEmailChanged]/[email] (the e-mail/senha form's own field): the two
  /// flows never share a single e-mail input, so switching between them
  /// never clears what the user already typed in the other one.
  const factory LoginEvent.corporateSsoEmailChanged(String email) =
      LoginCorporateSsoEmailChanged;

  /// Submits the corporate SSO login flow (TASK-173) — resolves which
  /// organization [LoginState.corporateSsoEmail]'s domain routes to,
  /// authenticates against that organization's registered IdP, then
  /// completes the just-in-time provisioning/RBAC decision, in that order
  /// (`SignInWithCorporateSsoUseCase`).
  const factory LoginEvent.corporateSsoSubmitted() = LoginCorporateSsoSubmitted;
}
