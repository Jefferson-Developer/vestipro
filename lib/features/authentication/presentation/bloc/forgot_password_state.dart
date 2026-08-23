import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/errors/errors.dart';

part 'forgot_password_state.freezed.dart';

/// The outcome of the last [ForgotPasswordEvent.submitted], kept separate
/// from the typed e-mail — same rationale as [LoginSubmissionStatus]
/// (TASK-034): a failed/loading submission never has to duplicate the typed
/// e-mail in a different state subclass, so it never has a reason to clear
/// it.
enum ForgotPasswordSubmissionStatus { idle, submitting, success, failure }

/// The single message shown for [ForgotPasswordSubmissionStatus.success],
/// regardless of whether the informed e-mail actually matches an existing
/// account (TASK-036) — never call [AppSnackbar.show] with any other string
/// for this status, or the flow becomes an account-enumeration oracle.
const String kPasswordResetGenericMessage =
    'Se o e-mail informado existir em nossa base, você receberá instruções '
    'para redefinir sua senha.';

@freezed
abstract class ForgotPasswordState with _$ForgotPasswordState {
  const factory ForgotPasswordState({
    @Default('') String email,

    /// `null` until the field has been validated at least once (first
    /// submit attempt) or until a fresh edit clears the previous error.
    String? emailError,
    @Default(ForgotPasswordSubmissionStatus.idle)
    ForgotPasswordSubmissionStatus status,

    /// Only meaningful when [status] is
    /// [ForgotPasswordSubmissionStatus.failure]. [Failure.message] is always
    /// the amiable, already-in-Portuguese message computed by
    /// `firebase_auth_exception_mapper.dart`/`SendPasswordResetEmailUseCase`
    /// — never a raw Firebase error code/string. Never populated for a
    /// `user-not-found` error: that case is mapped to
    /// [ForgotPasswordSubmissionStatus.success] before it ever reaches this
    /// bloc.
    Failure? failure,
  }) = _ForgotPasswordState;
}
