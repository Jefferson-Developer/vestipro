import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/errors/errors.dart';

part 'sign_up_state.freezed.dart';

/// The outcome of the last [SignUpEvent.submitted], kept separate from
/// field values — same rationale as [LoginSubmissionStatus] (TASK-034): a
/// failed/loading submission never has to duplicate the typed fields in a
/// different state subclass, so it never has a reason to clear them.
enum SignUpSubmissionStatus { idle, submitting, success, failure }

@freezed
abstract class SignUpState with _$SignUpState {
  const factory SignUpState({
    @Default('') String name,
    @Default('') String email,
    @Default('') String password,
    @Default('') String passwordConfirmation,

    /// `null` until the field has been validated at least once (first
    /// submit attempt) or until a fresh edit clears the previous error.
    String? nameError,
    String? emailError,
    String? passwordError,
    String? passwordConfirmationError,

    /// Whether the user checked the Terms of Service/Privacy Policy
    /// acceptance box. The submit button stays disabled while this is
    /// `false` — [termsError] is only ever shown if [SignUpEvent.submitted]
    /// somehow still fires while unchecked (e.g. a screen reader/testing
    /// bypass of the disabled button).
    @Default(false) bool termsAccepted,
    String? termsError,
    @Default(true) bool obscurePassword,
    @Default(true) bool obscurePasswordConfirmation,
    @Default(SignUpSubmissionStatus.idle) SignUpSubmissionStatus status,

    /// Only meaningful when [status] is [SignUpSubmissionStatus.failure].
    /// [Failure.message] is always the amiable, already-in-Portuguese
    /// message computed by `firebase_auth_exception_mapper.dart` — never a
    /// raw Firebase error code/string.
    Failure? failure,
  }) = _SignUpState;
}
