import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../bloc/forgot_password_bloc.dart';
import '../bloc/forgot_password_state.dart';
import '../widgets/forgot_password_form.dart';

/// The "forgot password" screen (TASK-036): requests a Firebase Auth
/// password reset e-mail.
///
/// Never talks to `AuthRepository`/`firebase_auth` itself: every field edit
/// and the submit action are dispatched to [ForgotPasswordBloc], same
/// rationale as `LoginPage` (TASK-034). The message shown for
/// [ForgotPasswordSubmissionStatus.success] is always
/// [kPasswordResetGenericMessage] — this page never has its own copy of
/// that string, so it can never accidentally diverge into something that
/// reveals whether the informed e-mail exists.
class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({required this.createBloc, super.key});

  final ForgotPasswordBloc Function() createBloc;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ForgotPasswordBloc>(
      create: (_) => createBloc(),
      child: const ForgotPasswordView(),
    );
  }
}

class ForgotPasswordView extends StatelessWidget {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: BlocListener<ForgotPasswordBloc, ForgotPasswordState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          switch (state.status) {
            case ForgotPasswordSubmissionStatus.success:
              AppSnackbar.show(
                context,
                message: kPasswordResetGenericMessage,
                variant: AppSnackbarVariant.success,
              );
            case ForgotPasswordSubmissionStatus.failure:
              final failure = state.failure;
              if (failure != null) {
                AppSnackbar.show(
                  context,
                  message: failure.message,
                  variant: AppSnackbarVariant.error,
                );
              }
            case ForgotPasswordSubmissionStatus.idle:
            case ForgotPasswordSubmissionStatus.submitting:
              break;
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacing24,
              vertical: AppSpacing.spacing32,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _ForgotPasswordHeadline(),
                    SizedBox(height: AppSpacing.spacing32),
                    ForgotPasswordForm(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ForgotPasswordHeadline extends StatelessWidget {
  const _ForgotPasswordHeadline();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Recuperar senha',
          style: AppTypography.headlineMedium.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: AppSpacing.spacing8),
        Text(
          'Informe seu e-mail e enviaremos as instruções para redefinir '
          'sua senha.',
          style: AppTypography.bodyMedium.copyWith(color: colors.onSurface),
        ),
      ],
    );
  }
}
