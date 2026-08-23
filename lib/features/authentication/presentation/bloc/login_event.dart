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
}
