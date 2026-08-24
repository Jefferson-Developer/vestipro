import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../permissions/permissions.dart';
import 'active_organization_guard.dart';
import 'app_route_paths.dart';
import 'auth_guard.dart';
import 'authorization_guard.dart';
import 'widgets/forbidden_page.dart';
import 'widgets/not_found_page.dart';

/// Single navigation entry point for VestiPro.
///
/// No feature may create its own [GoRouter] or navigate through raw
/// [Navigator] calls or string routes. Every authenticated route lives
/// under the `/org/:orgId/...` convention documented in
/// `docs/architecture/navigation.md`, and every guard is declared here so a
/// feature never has to reimplement one.
class AppRouter {
  AppRouter({
    required this.aboutAppPageBuilder,
    required this.auditLogPageBuilder,
    required this.loginPageBuilder,
    required this.signUpPageBuilder,
    required this.forgotPasswordPageBuilder,
    required this.onboardingWizardPageBuilder,
    required this.acceptInvitePageBuilder,
    this.customerFormPageBuilder,
    this.customerPortfolioPageBuilder,
    AuthGuard? authGuard,
    ActiveOrganizationGuard? organizationGuard,
    AuthorizationGuard? authorizationGuard,
  }) : authGuard = authGuard ?? const AlwaysAllowAuthGuard(),
       organizationGuard =
           organizationGuard ?? const AlwaysAllowActiveOrganizationGuard(),
       authorizationGuard =
           authorizationGuard ?? const AlwaysAllowAuthorizationGuard();

  final AuthGuard authGuard;
  final ActiveOrganizationGuard organizationGuard;
  final AuthorizationGuard authorizationGuard;
  final Widget Function(BuildContext context, String orgId) aboutAppPageBuilder;
  final Widget Function(BuildContext context, String orgId) auditLogPageBuilder;
  final Widget Function(BuildContext context, String orgId, String companyId)?
  customerFormPageBuilder;
  final Widget Function(
    BuildContext context,
    String orgId,
    String companyId,
    Map<String, String> queryParameters,
  )?
  customerPortfolioPageBuilder;

  /// Builds the real login screen (TASK-034). Injected from `VestiProApp`
  /// instead of imported here so `lib/core/navigation/` never depends on a
  /// concrete `lib/features/authentication/` widget — same composition
  /// rationale as [aboutAppPageBuilder].
  final WidgetBuilder loginPageBuilder;

  /// Builds the real sign-up screen (TASK-035). Same composition rationale
  /// as [loginPageBuilder].
  final WidgetBuilder signUpPageBuilder;

  /// Builds the real "forgot password" screen (TASK-036). Same composition
  /// rationale as [loginPageBuilder].
  final WidgetBuilder forgotPasswordPageBuilder;

  /// Builds the real onboarding wizard screen (TASK-038). Same composition
  /// rationale as [loginPageBuilder].
  final WidgetBuilder onboardingWizardPageBuilder;

  /// Builds the real invite-acceptance screen (TASK-040), given the `token`
  /// path parameter extracted from [InviteAcceptanceRoute]. Same
  /// composition rationale as [loginPageBuilder].
  final Widget Function(BuildContext context, String token)
  acceptInvitePageBuilder;

  late final GoRouter router = GoRouter(
    initialLocation: const AboutAppRoute(
      orgId: kPlaceholderOrganizationId,
    ).location,
    redirect: _redirect,
    routes: [
      GoRoute(
        path: AboutAppRoute.pathPattern,
        name: AboutAppRoute.name,
        builder: (context, state) =>
            aboutAppPageBuilder(context, state.pathParameters['orgId']!),
      ),
      GoRoute(
        path: AuditLogRoute.pathPattern,
        name: AuditLogRoute.name,
        redirect: (context, state) => authorizationGuard.redirect(
          context,
          state,
          requiredCapability: Capability.auditLogView,
        ),
        builder: (context, state) =>
            auditLogPageBuilder(context, state.pathParameters['orgId']!),
      ),
      GoRoute(
        path: CustomerPortfolioRoute.pathPattern,
        name: CustomerPortfolioRoute.name,
        redirect: (context, state) => authorizationGuard.redirect(
          context,
          state,
          requiredCapability: Capability.customerView,
        ),
        builder: (context, state) {
          final builder = customerPortfolioPageBuilder;
          if (builder == null) return const NotFoundPage();
          return builder(
            context,
            state.pathParameters['orgId']!,
            state.pathParameters['companyId']!,
            state.uri.queryParameters,
          );
        },
      ),
      GoRoute(
        path: CustomerFormRoute.pathPattern,
        name: CustomerFormRoute.name,
        redirect: (context, state) => authorizationGuard.redirect(
          context,
          state,
          requiredCapability: Capability.customerCreate,
        ),
        builder: (context, state) {
          final builder = customerFormPageBuilder;
          if (builder == null) return const NotFoundPage();
          return builder(
            context,
            state.pathParameters['orgId']!,
            state.pathParameters['companyId']!,
          );
        },
      ),
      GoRoute(
        path: LoginRoute.pathPattern,
        name: LoginRoute.name,
        builder: (context, state) => loginPageBuilder(context),
      ),
      GoRoute(
        path: SignUpRoute.pathPattern,
        name: SignUpRoute.name,
        builder: (context, state) => signUpPageBuilder(context),
      ),
      GoRoute(
        path: PasswordResetRoute.pathPattern,
        name: PasswordResetRoute.name,
        builder: (context, state) => forgotPasswordPageBuilder(context),
      ),
      GoRoute(
        path: OnboardingWizardRoute.pathPattern,
        name: OnboardingWizardRoute.name,
        builder: (context, state) => onboardingWizardPageBuilder(context),
      ),
      GoRoute(
        path: InviteAcceptanceRoute.pathPattern,
        name: InviteAcceptanceRoute.name,
        builder: (context, state) =>
            acceptInvitePageBuilder(context, state.pathParameters['token']!),
      ),
      GoRoute(
        path: ForbiddenRoute.pathPattern,
        name: ForbiddenRoute.name,
        builder: (context, state) => const ForbiddenPage(),
      ),
    ],
    errorBuilder: (context, state) => const NotFoundPage(),
  );

  Future<String?> _redirect(BuildContext context, GoRouterState state) async {
    final authRedirect = await authGuard.redirect(context, state);
    if (authRedirect != null) return authRedirect;
    if (!context.mounted) return null;

    return organizationGuard.redirect(context, state);
  }
}
