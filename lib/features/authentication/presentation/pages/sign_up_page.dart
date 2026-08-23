import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/navigation.dart';
import '../bloc/sign_up_bloc.dart';
import '../bloc/sign_up_state.dart';
import '../widgets/sign_up_form.dart';

/// The initial account creation screen (TASK-035): name, e-mail, password,
/// confirmation and the Terms of Service/Privacy Policy acceptance.
///
/// Never talks to `FirebaseAuth`/`AuthRepository`/`UserProfileRepository`
/// itself — every field edit and the submit action are dispatched to
/// [SignUpBloc], same rationale as `LoginPage` (TASK-034).
class SignUpPage extends StatelessWidget {
  const SignUpPage({required this.createBloc, super.key});

  final SignUpBloc Function() createBloc;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SignUpBloc>(
      create: (_) => createBloc(),
      child: const SignUpView(),
    );
  }
}

class SignUpView extends StatelessWidget {
  const SignUpView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: BlocListener<SignUpBloc, SignUpState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          switch (state.status) {
            case SignUpSubmissionStatus.success:
              // The real onboarding wizard does not exist yet
              // (TASK-037/TASK-038); this placeholder destination is the
              // same "declared ahead of implementation" precedent as
              // `PasswordResetRoute` before TASK-036 — see
              // `OnboardingWizardRoute`'s own doc comment.
              context.go(const OnboardingWizardRoute().location);
            case SignUpSubmissionStatus.failure:
              final failure = state.failure;
              if (failure != null) {
                AppSnackbar.show(
                  context,
                  message: failure.message,
                  variant: AppSnackbarVariant.error,
                );
              }
            case SignUpSubmissionStatus.idle:
            case SignUpSubmissionStatus.submitting:
              break;
          }
        },
        child: SafeArea(
          child: AppResponsiveBuilder(
            builder: (context, breakpoint) {
              final isWide =
                  breakpoint == AppBreakpoint.desktop ||
                  breakpoint == AppBreakpoint.largeDesktop;
              return isWide
                  ? const _WideSignUpLayout()
                  : const _CompactSignUpLayout();
            },
          ),
        ),
      ),
    );
  }
}

/// Single-column layout for phones and tablets: headline on top, form
/// below, scrollable so the keyboard never covers the field currently
/// focused — same structure as `LoginPage`'s compact layout.
class _CompactSignUpLayout extends StatelessWidget {
  const _CompactSignUpLayout();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
              _SignUpHeadline(),
              SizedBox(height: AppSpacing.spacing32),
              SignUpForm(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Split layout for desktop/wide web windows: a brand panel on the left and
/// the form panel on the right — same structure as `LoginPage`'s wide
/// layout.
class _WideSignUpLayout extends StatelessWidget {
  const _WideSignUpLayout();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(flex: 5, child: _BrandPanel()),
        Expanded(
          flex: 4,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.spacing48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _SignUpHeadline(),
                    SizedBox(height: AppSpacing.spacing32),
                    SignUpForm(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      color: colors.primary,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppSpacing.spacing48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            label: 'VestiPro',
            image: true,
            child: Image.asset(
              'assets/images/logo.png',
              height: 120,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing24),
          Text(
            'A força de vendas do seu jeito.',
            textAlign: TextAlign.center,
            style: AppTypography.titleLarge.copyWith(color: colors.onPrimary),
          ),
        ],
      ),
    );
  }
}

class _SignUpHeadline extends StatelessWidget {
  const _SignUpHeadline();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Crie sua conta',
          style: AppTypography.headlineMedium.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: AppSpacing.spacing8),
        Text(
          'Comece a organizar sua carteira e seus pedidos em minutos.',
          style: AppTypography.bodyMedium.copyWith(color: colors.onSurface),
        ),
      ],
    );
  }
}
