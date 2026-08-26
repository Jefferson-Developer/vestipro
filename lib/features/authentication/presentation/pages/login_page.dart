import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/navigation.dart';
import '../bloc/login_bloc.dart';
import '../bloc/login_state.dart';
import '../widgets/login_form.dart';

/// The e-mail/password login screen (TASK-034) — the entry point of every
/// VestiPro session and the user's first contact with the Design System.
///
/// Never talks to `FirebaseAuth`/[AuthRepository] itself: every field edit
/// and the submit action are dispatched to [LoginBloc], which owns the
/// use case call, the validation and the analytics event.
class LoginPage extends StatelessWidget {
  const LoginPage({required this.createBloc, super.key});

  final LoginBloc Function() createBloc;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LoginBloc>(
      create: (_) => createBloc(),
      child: const LoginView(),
    );
  }
}

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: BlocListener<LoginBloc, LoginState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          switch (state.status) {
            case LoginSubmissionStatus.success:
              context.go(_resolvePostLoginDestination(context, state));
            case LoginSubmissionStatus.failure:
              final failure = state.failure;
              if (failure != null) {
                AppSnackbar.show(
                  context,
                  message: failure.message,
                  variant: AppSnackbarVariant.error,
                );
              }
            case LoginSubmissionStatus.idle:
            case LoginSubmissionStatus.submitting:
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
                  ? const _WideLoginLayout()
                  : const _CompactLoginLayout();
            },
          ),
        ),
      ),
    );
  }
}

/// Where to navigate right after a successful [LoginSubmissionStatus.success]
/// — in priority order:
///
/// 1. Back to whatever protected route originally sent the user to
///    [LoginRoute] with a `returnTo` query parameter (deep link,
///    `SessionAuthGuard`), when it is safe to reuse as-is.
/// 2. [OnboardingWizardRoute], when [LoginBloc] resolved that this user has
///    no active Organization Membership yet ([LoginState.requiresOnboarding]).
/// 3. [CatalogHomeRoute] scoped to [LoginState.organizationId], the real
///    Organization [LoginBloc] resolved for this user
///    (`ResolveActiveOrganizationIdUseCase`) — the common case.
/// 4. [kPlaceholderOrganizationId] as a last-resort fallback, only reached
///    when that resolution itself failed (e.g. offline). `ActiveOrganizationGuard`
///    still fails closed from there on the very next navigation, so this
///    never actually grants access to anything.
String _resolvePostLoginDestination(BuildContext context, LoginState state) {
  final safeReturnTo = _safeReturnToFrom(context);
  if (safeReturnTo != null) return safeReturnTo;

  if (state.requiresOnboarding) return const OnboardingWizardRoute().location;

  final organizationId = state.organizationId;
  if (organizationId != null && organizationId.isNotEmpty) {
    return CatalogHomeRoute(orgId: organizationId).location;
  }

  return const CatalogHomeRoute(orgId: kPlaceholderOrganizationId).location;
}

String? _safeReturnToFrom(BuildContext context) {
  try {
    final returnTo = GoRouterState.of(context).uri.queryParameters['returnTo'];
    return _safeReturnTo(returnTo);
  } catch (_) {
    return null;
  }
}

String? _safeReturnTo(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  if (!trimmed.startsWith('/') || trimmed.startsWith('//')) return null;

  final uri = Uri.tryParse(trimmed);
  if (uri == null || uri.hasScheme || uri.hasAuthority) return null;
  if (uri.path == LoginRoute.pathPattern) return null;

  return uri.toString();
}

/// Single-column layout for phones and tablets: logo on top, form below,
/// scrollable so the keyboard never covers the field currently focused.
class _CompactLoginLayout extends StatelessWidget {
  const _CompactLoginLayout();

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
              _LoginLogo(height: 72),
              SizedBox(height: AppSpacing.spacing32),
              _LoginHeadline(),
              SizedBox(height: AppSpacing.spacing32),
              LoginForm(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Split layout for desktop/wide web windows: a brand panel on the left and
/// the form panel on the right, so the sign-in screen reads as an
/// editorial, fashion-forward moment instead of a bare form.
class _WideLoginLayout extends StatelessWidget {
  const _WideLoginLayout();

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
                    _LoginHeadline(),
                    SizedBox(height: AppSpacing.spacing32),
                    LoginForm(),
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
          const _LoginLogo(height: 120),
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

class _LoginLogo extends StatelessWidget {
  const _LoginLogo({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'VestiPro',
      image: true,
      child: Image.asset(
        'assets/images/logo.png',
        height: height,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _LoginHeadline extends StatelessWidget {
  const _LoginHeadline();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Bem-vindo de volta',
          style: AppTypography.headlineMedium.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: AppSpacing.spacing8),
        Text(
          'Entre com seu e-mail e senha para acessar sua carteira.',
          style: AppTypography.bodyMedium.copyWith(color: colors.onSurface),
        ),
      ],
    );
  }
}
