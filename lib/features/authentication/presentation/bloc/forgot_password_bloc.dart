import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/usecases/send_password_reset_email_use_case.dart';
import '../../domain/validators/login_form_validators.dart';
import 'forgot_password_event.dart';
import 'forgot_password_state.dart';

/// Drives the "forgot password" screen (TASK-036): the typed e-mail and the
/// submit flow against [SendPasswordResetEmailUseCase].
///
/// [ForgotPasswordPage]/`ForgotPasswordForm` never call
/// [SendPasswordResetEmailUseCase]'s dependencies (`AuthRepository`/
/// `firebase_auth`) directly — every state transition goes through this
/// bloc, same rationale as [LoginBloc] (TASK-034). Reuses
/// [validateLoginEmail] instead of duplicating the e-mail format check: the
/// rule ("looks like an e-mail") is identical to the login form's, only the
/// destination use case differs.
@injectable
final class ForgotPasswordBloc
    extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  ForgotPasswordBloc({
    required this.sendPasswordResetEmail,
    required this.analyticsService,
  }) : super(const ForgotPasswordState()) {
    on<ForgotPasswordEmailChanged>(_onEmailChanged);
    // `droppable`: a second SUBMITTED while one is already in flight is
    // ignored at the bloc level too — defense in depth on top of
    // `AppButton`'s own tap-lock/`isLoading` guard on the widget side.
    on<ForgotPasswordSubmitted>(_onSubmitted, transformer: droppable());
  }

  final SendPasswordResetEmailUseCase sendPasswordResetEmail;
  final AnalyticsService analyticsService;

  void _onEmailChanged(
    ForgotPasswordEmailChanged event,
    Emitter<ForgotPasswordState> emit,
  ) {
    emit(
      state.copyWith(
        email: event.email,
        emailError: null,
        status: ForgotPasswordSubmissionStatus.idle,
        failure: null,
      ),
    );
  }

  Future<void> _onSubmitted(
    ForgotPasswordSubmitted event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    final email = state.email.trim();
    final emailError = validateLoginEmail(email);

    if (emailError != null) {
      emit(
        state.copyWith(
          emailError: emailError,
          status: ForgotPasswordSubmissionStatus.idle,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: ForgotPasswordSubmissionStatus.submitting,
        emailError: null,
        failure: null,
      ),
    );

    final result = await sendPasswordResetEmail(email: email);
    if (emit.isDone) {
      return;
    }

    switch (result) {
      case AppSuccess<void>():
        // Only technical metadata — never the e-mail — per the LGPD
        // restriction on `AnalyticsService.logEvent` (see `AGENTS.md`). Also
        // fired for the `user-not-found` case, which
        // [SendPasswordResetEmailUseCase] already turned into this same
        // success branch, so this event alone never reveals whether the
        // account exists.
        await analyticsService.logEvent(
          AnalyticsEvents.passwordResetRequested,
          parameters: <String, Object?>{'platform': defaultTargetPlatform.name},
        );
        emit(state.copyWith(status: ForgotPasswordSubmissionStatus.success));
      case AppFailure<void>(failure: final failure):
        emit(
          state.copyWith(
            status: ForgotPasswordSubmissionStatus.failure,
            failure: failure,
          ),
        );
    }
  }
}
