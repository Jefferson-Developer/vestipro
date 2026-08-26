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

    /// Only meaningful when [status] is [LoginSubmissionStatus.success]: the
    /// real Organization `ResolveActiveOrganizationIdUseCase` resolved for
    /// the signed-in user right after authenticating, `null` when it could
    /// not be resolved (no Membership yet, or the resolution itself failed —
    /// `LoginBloc` never blocks a successful sign-in on this). `LoginPage`
    /// falls back to `kPlaceholderOrganizationId` when this is `null` and
    /// [requiresOnboarding] is also `false`, same precedent as
    /// `ActiveOrganizationGuard`'s own fail-closed default.
    String? organizationId,

    /// Only meaningful when [status] is [LoginSubmissionStatus.success]:
    /// `true` when the resolution above succeeded but found no active
    /// Membership at all — the signed-in user has never completed
    /// onboarding, so `LoginPage` sends them to `OnboardingWizardRoute`
    /// instead of a placeholder Organization scope.
    @Default(false) bool requiresOnboarding,
  }) = _LoginState;
}
