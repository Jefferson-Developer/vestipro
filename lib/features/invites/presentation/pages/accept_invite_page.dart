import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../authentication/presentation/bloc/sign_up_bloc.dart';
import '../../../authentication/presentation/bloc/sign_up_state.dart';
import '../../../authentication/presentation/widgets/sign_up_form.dart';
import '../../domain/value_objects/invite_acceptance_outcome.dart';
import '../bloc/accept_invite_bloc.dart';
import '../bloc/accept_invite_event.dart';
import '../bloc/accept_invite_state.dart';
import 'invite_user_page.dart' show systemRoleNameLabel;

/// The invite-acceptance screen reached via `/invite/:token` (TASK-040):
/// validates the token against `validateInvite` *before* showing any
/// option, then either lets the visitor create a brand-new account
/// (e-mail locked to the invite's, reusing `SignUpForm` from TASK-035) or,
/// if already signed in with a matching e-mail, just confirms the vínculo.
///
/// Never talks to `ValidateInviteUseCase`/`AcceptInviteUseCase`/
/// `AuthRepository` directly — every transition goes through
/// [AcceptInviteBloc], same rationale as `SignUpPage`/`OnboardingWizardPage`.
class AcceptInvitePage extends StatelessWidget {
  const AcceptInvitePage({
    required this.token,
    required this.createBloc,
    required this.createSignUpBloc,
    super.key,
  });

  final String token;
  final AcceptInviteBloc Function() createBloc;

  /// Builds the `SignUpBloc` powering the embedded `SignUpForm` for the
  /// "brand-new account" flow — injected the same way every other page
  /// builder in `AppRouter` is, so this feature never reaches into a
  /// concrete DI container itself.
  final SignUpBloc Function() createSignUpBloc;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AcceptInviteBloc>(
      create: (_) => createBloc()..add(AcceptInviteEvent.started(token)),
      child: AcceptInviteView(createSignUpBloc: createSignUpBloc),
    );
  }
}

class AcceptInviteView extends StatelessWidget {
  const AcceptInviteView({required this.createSignUpBloc, super.key});

  final SignUpBloc Function() createSignUpBloc;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: BlocListener<AcceptInviteBloc, AcceptInviteState>(
        listenWhen: (previous, current) =>
            previous.acceptanceStatus != current.acceptanceStatus,
        listener: (context, state) {
          switch (state.acceptanceStatus) {
            case AcceptInviteAcceptanceStatus.success:
              final organizationId = state.acceptedOrganizationId;
              if (organizationId != null) {
                context.go(CatalogHomeRoute(orgId: organizationId).location);
              }
            case AcceptInviteAcceptanceStatus.failure:
              final failure = state.failure;
              if (failure != null) {
                AppSnackbar.show(
                  context,
                  message: failure.message,
                  variant: AppSnackbarVariant.error,
                );
              }
            case AcceptInviteAcceptanceStatus.idle:
            case AcceptInviteAcceptanceStatus.submitting:
              break;
          }
        },
        child: SafeArea(
          child: BlocBuilder<AcceptInviteBloc, AcceptInviteState>(
            builder: (context, state) {
              return switch (state.validationStatus) {
                AcceptInviteValidationStatus.loading => const Center(
                  child: CircularProgressIndicator(),
                ),
                AcceptInviteValidationStatus.error => AppErrorState(
                  title: 'Não foi possível validar o convite',
                  message:
                      state.failure?.message ??
                      'Tente novamente em alguns instantes.',
                  retryLabel: 'Tentar novamente',
                  onRetry: () => context.read<AcceptInviteBloc>().add(
                    AcceptInviteEvent.started(state.token),
                  ),
                ),
                AcceptInviteValidationStatus.ready =>
                  state.outcome == InviteAcceptanceOutcome.valid
                      ? _ValidInviteContent(createSignUpBloc: createSignUpBloc)
                      : _InvalidInviteContent(outcome: state.outcome),
              };
            },
          ),
        ),
      ),
    );
  }
}

/// One clear, specific message per non-`valid` [InviteAcceptanceOutcome] —
/// never a raw technical error (TASK-040's own acceptance criteria).
class _InvalidInviteContent extends StatelessWidget {
  const _InvalidInviteContent({required this.outcome});

  final InviteAcceptanceOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final (title, message) = switch (outcome) {
      InviteAcceptanceOutcome.notFound => (
        'Convite não encontrado',
        'Verifique se o link está completo ou solicite um novo convite a '
            'quem administra sua organização.',
      ),
      InviteAcceptanceOutcome.expired => (
        'Convite expirado',
        'Este link de convite não é mais válido. Solicite um novo convite '
            'a quem administra sua organização.',
      ),
      InviteAcceptanceOutcome.accepted => (
        'Convite já utilizado',
        'Este convite já foi aceito anteriormente. Se você acredita que '
            'isso é um engano, solicite um novo convite.',
      ),
      InviteAcceptanceOutcome.revoked => (
        'Convite revogado',
        'Este convite foi revogado por um administrador. Solicite um novo '
            'convite, se necessário.',
      ),
      // Defensive only: `AcceptInviteView` never renders this widget for
      // `valid` — kept exhaustive rather than a wildcard so a new
      // `InviteAcceptanceOutcome` value fails to compile here instead of
      // silently falling back to a generic message.
      InviteAcceptanceOutcome.valid => (
        'Convite indisponível',
        'Não foi possível continuar com este convite agora.',
      ),
    };

    return AppErrorState(
      icon: Icons.mail_outline,
      title: title,
      message: message,
    );
  }
}

/// The invite's organization/role context, shown above every "valid
/// outcome" sub-flow ([_NewAccountInviteContent], [_ConfirmInviteContent],
/// [_EmailMismatchContent]).
class _InviteHeader extends StatelessWidget {
  const _InviteHeader({required this.state});

  final AcceptInviteState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final organizationName = state.organizationName ?? 'sua organização';
    final roleName = state.roleName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Você foi convidado',
          style: AppTypography.headlineMedium.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: AppSpacing.spacing8),
        Text(
          roleName == null
              ? 'Você foi convidado para entrar em $organizationName.'
              : 'Você foi convidado para entrar em $organizationName como '
                    '${systemRoleNameLabel(roleName)}.',
          style: AppTypography.bodyMedium.copyWith(color: colors.onSurface),
        ),
      ],
    );
  }
}

/// Branches the "valid outcome" case on the current session, per TASK-040's
/// documented e-mail-divergence rule (blocked, never silently allowed).
class _ValidInviteContent extends StatelessWidget {
  const _ValidInviteContent({required this.createSignUpBloc});

  final SignUpBloc Function() createSignUpBloc;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AcceptInviteBloc, AcceptInviteState>(
      builder: (context, state) {
        if (state.acceptanceStatus == AcceptInviteAcceptanceStatus.submitting ||
            state.acceptanceStatus == AcceptInviteAcceptanceStatus.success) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!state.hasActiveSession) {
          return _NewAccountInviteContent(
            state: state,
            createSignUpBloc: createSignUpBloc,
          );
        }
        if (state.sessionEmailMismatch) {
          return _EmailMismatchContent(state: state);
        }
        return _ConfirmInviteContent(state: state);
      },
    );
  }
}

class _CenteredFormColumn extends StatelessWidget {
  const _CenteredFormColumn({required this.children});

  final List<Widget> children;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// No active session: creates a brand-new account through the same
/// [SignUpForm] `SignUpPage` uses (TASK-035), with the e-mail field locked
/// to the invite's own address — TASK-040's documented e-mail-divergence
/// rule means this form never lets anyone type a different one.
class _NewAccountInviteContent extends StatelessWidget {
  const _NewAccountInviteContent({
    required this.state,
    required this.createSignUpBloc,
  });

  final AcceptInviteState state;
  final SignUpBloc Function() createSignUpBloc;

  @override
  Widget build(BuildContext context) {
    return _CenteredFormColumn(
      children: <Widget>[
        _InviteHeader(state: state),
        const SizedBox(height: AppSpacing.spacing32),
        BlocProvider<SignUpBloc>(
          create: (_) => createSignUpBloc(),
          child: BlocListener<SignUpBloc, SignUpState>(
            listenWhen: (previous, current) =>
                previous.status != current.status,
            listener: (context, signUpState) {
              switch (signUpState.status) {
                case SignUpSubmissionStatus.success:
                  context.read<AcceptInviteBloc>().add(
                    const AcceptInviteEvent.confirmed(),
                  );
                case SignUpSubmissionStatus.failure:
                  final failure = signUpState.failure;
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
            child: SignUpForm(
              initialEmail: state.invitedEmail,
              lockEmail: true,
              showAlternateAuthLink: false,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.spacing16),
        Align(
          alignment: Alignment.center,
          child: AppButton(
            label: 'Já tem conta? Entrar',
            variant: AppButtonVariant.text,
            onPressed: () => context.go(const LoginRoute().location),
          ),
        ),
      ],
    );
  }
}

/// Already signed in with an e-mail matching the invite: a single
/// confirmation step, never a role choice (always the invite's own role).
class _ConfirmInviteContent extends StatelessWidget {
  const _ConfirmInviteContent({required this.state});

  final AcceptInviteState state;

  @override
  Widget build(BuildContext context) {
    return _CenteredFormColumn(
      children: <Widget>[
        _InviteHeader(state: state),
        const SizedBox(height: AppSpacing.spacing32),
        AppButton(
          label: 'Aceitar convite',
          expand: true,
          onPressed: () => context.read<AcceptInviteBloc>().add(
            const AcceptInviteEvent.confirmed(),
          ),
        ),
      ],
    );
  }
}

/// Already signed in, but with an e-mail that diverges from the invite's —
/// blocked (TASK-040's documented rule), steering the visitor to sign out
/// before continuing.
class _EmailMismatchContent extends StatelessWidget {
  const _EmailMismatchContent({required this.state});

  final AcceptInviteState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final invitedEmail = state.invitedEmail ?? '';

    return _CenteredFormColumn(
      children: <Widget>[
        Icon(
          Icons.warning_amber_outlined,
          size: AppIconSizes.xxl,
          color: colors.warning,
        ),
        const SizedBox(height: AppSpacing.spacing16),
        Text(
          'E-mail diferente do convite',
          style: AppTypography.titleMedium.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: AppSpacing.spacing8),
        Text(
          'Este convite foi enviado para $invitedEmail, mas você está '
          'autenticado com outra conta. Saia da conta atual para criar ou '
          'entrar com a conta correta.',
          style: AppTypography.bodyMedium.copyWith(color: colors.outline),
        ),
        const SizedBox(height: AppSpacing.spacing24),
        AppButton(
          label: 'Sair e continuar',
          expand: true,
          onPressed: () => context.read<AcceptInviteBloc>().add(
            const AcceptInviteEvent.signOutRequested(),
          ),
        ),
      ],
    );
  }
}
