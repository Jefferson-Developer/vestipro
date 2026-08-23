import 'package:freezed_annotation/freezed_annotation.dart';

part 'forgot_password_event.freezed.dart';

@freezed
sealed class ForgotPasswordEvent with _$ForgotPasswordEvent {
  const factory ForgotPasswordEvent.emailChanged(String email) =
      ForgotPasswordEmailChanged;

  const factory ForgotPasswordEvent.submitted() = ForgotPasswordSubmitted;
}
