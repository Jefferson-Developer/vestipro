import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/errors/errors.dart';

part 'login_state.freezed.dart';

/// The outcome of the last [LoginEvent.submitted], kept separate from field
/// values so a failed/loading submission never has to duplicate
/// `email`/`password` in a different state subclass — and, critically,
/// never has a reason to clear them.
enum LoginSubmissionStatus { idle, submitting, success, failure }

@freezed
abstract class LoginState with _$LoginState {
  const factory LoginState({
    @Default('') String email,
    @Default('') String password,

    /// `null` until the field has been validated at least once (first
    /// submit attempt) or until a fresh edit clears the previous error.
    String? emailError,
    String? passwordError,
    @Default(true) bool obscurePassword,
    @Default(LoginSubmissionStatus.idle) LoginSubmissionStatus status,

    /// Only meaningful when [status] is [LoginSubmissionStatus.failure].
    /// [Failure.message] is always the amiable, already-in-Portuguese
    /// message computed by `firebase_auth_exception_mapper.dart` — never a
    /// raw Firebase error code/string.
    Failure? failure,
  }) = _LoginState;
}
