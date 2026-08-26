import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/auth/auth.dart';
import '../../../../core/utils/utils.dart';
import '../../../organizations/domain/usecases/resolve_active_organization_id_use_case.dart';
import '../../domain/usecases/sign_in_with_email_and_password_use_case.dart';
import '../../domain/validators/login_form_validators.dart';
import 'login_event.dart';
import 'login_state.dart';

/// Drives the login screen (TASK-034): field edits, the password visibility
/// toggle and the submit flow against [SignInWithEmailAndPasswordUseCase].
///
/// [LoginPage]/[LoginForm] never call [AuthRepository]/`firebase_auth`
/// directly — every state transition goes through this bloc, which is the
/// only place that decides when a field is invalid, when a submission is in
/// flight and what the resulting [LoginState.failure] message is.
///
/// A successful sign-in also resolves the real Organization to land on
/// ([resolveActiveOrganizationId] — replaces the `kPlaceholderOrganizationId`
/// every post-login navigation used to hardcode) — never leaving that
/// decision to `LoginPage`, same rationale as every other business decision
/// this bloc already owns.
@injectable
final class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({
    required this.signInWithEmailAndPassword,
    required this.resolveActiveOrganizationId,
    required this.analyticsService,
  }) : super(const LoginState()) {
    on<LoginEmailChanged>(_onEmailChanged);
    on<LoginPasswordChanged>(_onPasswordChanged);
    on<LoginPasswordVisibilityToggled>(_onPasswordVisibilityToggled);
    // `droppable`: a second SUBMITTED while one is already in flight is
    // ignored at the bloc level too — defense in depth on top of
    // `AppButton`'s own tap-lock/`isLoading` guard on the widget side.
    on<LoginSubmitted>(_onSubmitted, transformer: droppable());
  }

  final SignInWithEmailAndPasswordUseCase signInWithEmailAndPassword;
  final ResolveActiveOrganizationIdUseCase resolveActiveOrganizationId;
  final AnalyticsService analyticsService;

  void _onEmailChanged(LoginEmailChanged event, Emitter<LoginState> emit) {
    emit(
      state.copyWith(
        email: event.email,
        emailError: null,
        status: LoginSubmissionStatus.idle,
        failure: null,
      ),
    );
  }

  void _onPasswordChanged(
    LoginPasswordChanged event,
    Emitter<LoginState> emit,
  ) {
    emit(
      state.copyWith(
        password: event.password,
        passwordError: null,
        status: LoginSubmissionStatus.idle,
        failure: null,
      ),
    );
  }

  void _onPasswordVisibilityToggled(
    LoginPasswordVisibilityToggled event,
    Emitter<LoginState> emit,
  ) {
    emit(state.copyWith(obscurePassword: !state.obscurePassword));
  }

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    final email = state.email.trim();
    final password = state.password;
    final emailError = validateLoginEmail(email);
    final passwordError = validateLoginPassword(password);

    if (emailError != null || passwordError != null) {
      emit(
        state.copyWith(
          emailError: emailError,
          passwordError: passwordError,
          status: LoginSubmissionStatus.idle,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: LoginSubmissionStatus.submitting,
        emailError: null,
        passwordError: null,
        failure: null,
      ),
    );

    final result = await signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (emit.isDone) {
      return;
    }

    switch (result) {
      case AppSuccess<SessionUser>(value: final sessionUser):
        // Only technical metadata — never the e-mail/uid — per the LGPD
        // restriction on `AnalyticsService.logEvent` (see `AGENTS.md`).
        await analyticsService.logEvent(
          AnalyticsEvents.loginCompleted,
          parameters: <String, Object?>{
            'method': 'email',
            'platform': defaultTargetPlatform.name,
          },
        );
        if (emit.isDone) {
          return;
        }

        final organizationResult = await resolveActiveOrganizationId(
          userId: sessionUser.uid,
        );
        if (emit.isDone) {
          return;
        }

        organizationResult.fold(
          onSuccess: (organizationId) => emit(
            state.copyWith(
              status: LoginSubmissionStatus.success,
              organizationId: organizationId,
              requiresOnboarding: organizationId == null,
            ),
          ),
          // A resolution failure (e.g. offline before any Membership was
          // ever cached locally) must never turn an already-successful
          // sign-in into a failure screen: `LoginPage` falls back to
          // `kPlaceholderOrganizationId`, and `ActiveOrganizationGuard`
          // fails closed from there on the very next navigation — same
          // precedent as `PermissionAuthorizationGuard`.
          onFailure: (_) =>
              emit(state.copyWith(status: LoginSubmissionStatus.success)),
        );
      case AppFailure<SessionUser>(failure: final failure):
        emit(
          state.copyWith(
            status: LoginSubmissionStatus.failure,
            failure: failure,
          ),
        );
    }
  }
}
