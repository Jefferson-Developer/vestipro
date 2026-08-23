import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/auth/auth.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/usecases/create_account_with_email_and_password_use_case.dart';
import '../../domain/validators/sign_up_form_validators.dart';
import '../../domain/value_objects/terms_of_service_version.dart';
import 'sign_up_event.dart';
import 'sign_up_state.dart';

/// Drives the sign-up screen (TASK-035): field edits, the password/
/// confirmation visibility toggles, the terms-of-service acceptance
/// checkbox and the submit flow against
/// [CreateAccountWithEmailAndPasswordUseCase].
///
/// [SignUpPage]/[SignUpForm] never call [AuthRepository]/`firebase_auth` or
/// `UserProfileRepository`/Firestore directly — every state transition goes
/// through this bloc, same rationale as [LoginBloc] (TASK-034).
@injectable
final class SignUpBloc extends Bloc<SignUpEvent, SignUpState> {
  SignUpBloc({
    required this.createAccountWithEmailAndPassword,
    required this.analyticsService,
  }) : super(const SignUpState()) {
    on<SignUpNameChanged>(_onNameChanged);
    on<SignUpEmailChanged>(_onEmailChanged);
    on<SignUpPasswordChanged>(_onPasswordChanged);
    on<SignUpPasswordConfirmationChanged>(_onPasswordConfirmationChanged);
    on<SignUpPasswordVisibilityToggled>(_onPasswordVisibilityToggled);
    on<SignUpPasswordConfirmationVisibilityToggled>(
      _onPasswordConfirmationVisibilityToggled,
    );
    on<SignUpTermsAcceptanceToggled>(_onTermsAcceptanceToggled);
    // `droppable`: a second SUBMITTED while one is already in flight is
    // ignored at the bloc level too — defense in depth on top of
    // `AppButton`'s own tap-lock/`isLoading` guard on the widget side.
    on<SignUpSubmitted>(_onSubmitted, transformer: droppable());
  }

  final CreateAccountWithEmailAndPasswordUseCase
  createAccountWithEmailAndPassword;
  final AnalyticsService analyticsService;

  void _onNameChanged(SignUpNameChanged event, Emitter<SignUpState> emit) {
    emit(
      state.copyWith(
        name: event.name,
        nameError: null,
        status: SignUpSubmissionStatus.idle,
        failure: null,
      ),
    );
  }

  void _onEmailChanged(SignUpEmailChanged event, Emitter<SignUpState> emit) {
    emit(
      state.copyWith(
        email: event.email,
        emailError: null,
        status: SignUpSubmissionStatus.idle,
        failure: null,
      ),
    );
  }

  void _onPasswordChanged(
    SignUpPasswordChanged event,
    Emitter<SignUpState> emit,
  ) {
    emit(
      state.copyWith(
        password: event.password,
        passwordError: null,
        status: SignUpSubmissionStatus.idle,
        failure: null,
      ),
    );
  }

  void _onPasswordConfirmationChanged(
    SignUpPasswordConfirmationChanged event,
    Emitter<SignUpState> emit,
  ) {
    emit(
      state.copyWith(
        passwordConfirmation: event.passwordConfirmation,
        passwordConfirmationError: null,
        status: SignUpSubmissionStatus.idle,
        failure: null,
      ),
    );
  }

  void _onPasswordVisibilityToggled(
    SignUpPasswordVisibilityToggled event,
    Emitter<SignUpState> emit,
  ) {
    emit(state.copyWith(obscurePassword: !state.obscurePassword));
  }

  void _onPasswordConfirmationVisibilityToggled(
    SignUpPasswordConfirmationVisibilityToggled event,
    Emitter<SignUpState> emit,
  ) {
    emit(
      state.copyWith(
        obscurePasswordConfirmation: !state.obscurePasswordConfirmation,
      ),
    );
  }

  void _onTermsAcceptanceToggled(
    SignUpTermsAcceptanceToggled event,
    Emitter<SignUpState> emit,
  ) {
    emit(state.copyWith(termsAccepted: !state.termsAccepted, termsError: null));
  }

  Future<void> _onSubmitted(
    SignUpSubmitted event,
    Emitter<SignUpState> emit,
  ) async {
    final name = state.name.trim();
    final email = state.email.trim();
    final password = state.password;
    final passwordConfirmation = state.passwordConfirmation;

    final nameError = validateSignUpName(name);
    final emailError = validateSignUpEmail(email);
    final passwordError = validateSignUpPassword(password);
    final passwordConfirmationError = validateSignUpPasswordConfirmation(
      password,
      passwordConfirmation,
    );
    // Not a per-field validator (there is no string to validate): the
    // acceptance checkbox itself already keeps the submit button disabled,
    // this is only defense-in-depth for a submit that somehow still fires
    // (see `SignUpState.termsAccepted`'s doc).
    final termsError = state.termsAccepted
        ? null
        : 'É necessário aceitar os Termos de Uso e a Política de '
              'Privacidade.';

    if (nameError != null ||
        emailError != null ||
        passwordError != null ||
        passwordConfirmationError != null ||
        termsError != null) {
      emit(
        state.copyWith(
          nameError: nameError,
          emailError: emailError,
          passwordError: passwordError,
          passwordConfirmationError: passwordConfirmationError,
          termsError: termsError,
          status: SignUpSubmissionStatus.idle,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: SignUpSubmissionStatus.submitting,
        nameError: null,
        emailError: null,
        passwordError: null,
        passwordConfirmationError: null,
        termsError: null,
        failure: null,
      ),
    );

    final result = await createAccountWithEmailAndPassword(
      name: name,
      email: email,
      password: password,
      termsVersion: kCurrentTermsOfServiceVersion,
    );
    if (emit.isDone) {
      return;
    }

    switch (result) {
      case AppSuccess<SessionUser>():
        // Only technical metadata — never the name/e-mail/uid — per the
        // LGPD restriction on `AnalyticsService.logEvent` (see `AGENTS.md`).
        await analyticsService.logEvent(
          AnalyticsEvents.signUpCompleted,
          parameters: <String, Object?>{
            'method': 'email',
            'platform': defaultTargetPlatform.name,
          },
        );
        emit(state.copyWith(status: SignUpSubmissionStatus.success));
      case AppFailure<SessionUser>(failure: final failure):
        emit(
          state.copyWith(
            status: SignUpSubmissionStatus.failure,
            failure: failure,
          ),
        );
    }
  }
}
