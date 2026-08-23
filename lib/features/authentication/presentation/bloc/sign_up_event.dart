import 'package:freezed_annotation/freezed_annotation.dart';

part 'sign_up_event.freezed.dart';

@freezed
sealed class SignUpEvent with _$SignUpEvent {
  const factory SignUpEvent.nameChanged(String name) = SignUpNameChanged;

  const factory SignUpEvent.emailChanged(String email) = SignUpEmailChanged;

  const factory SignUpEvent.passwordChanged(String password) =
      SignUpPasswordChanged;

  const factory SignUpEvent.passwordConfirmationChanged(
    String passwordConfirmation,
  ) = SignUpPasswordConfirmationChanged;

  const factory SignUpEvent.passwordVisibilityToggled() =
      SignUpPasswordVisibilityToggled;

  const factory SignUpEvent.passwordConfirmationVisibilityToggled() =
      SignUpPasswordConfirmationVisibilityToggled;

  const factory SignUpEvent.termsAcceptanceToggled() =
      SignUpTermsAcceptanceToggled;

  const factory SignUpEvent.submitted() = SignUpSubmitted;
}
