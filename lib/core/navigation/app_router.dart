import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'active_organization_guard.dart';
import 'app_route_paths.dart';
import 'auth_guard.dart';
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
    required this.loginPageBuilder,
    AuthGuard? authGuard,
    ActiveOrganizationGuard? organizationGuard,
  }) : authGuard = authGuard ?? const AlwaysAllowAuthGuard(),
       organizationGuard =
           organizationGuard ?? const AlwaysAllowActiveOrganizationGuard();

  final AuthGuard authGuard;
  final ActiveOrganizationGuard organizationGuard;
  final Widget Function(BuildContext context, String orgId) aboutAppPageBuilder;

  /// Builds the real login screen (TASK-034). Injected from `VestiProApp`
  /// instead of imported here so `lib/core/navigation/` never depends on a
  /// concrete `lib/features/authentication/` widget — same composition
  /// rationale as [aboutAppPageBuilder].
  final WidgetBuilder loginPageBuilder;

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
        path: LoginRoute.pathPattern,
        name: LoginRoute.name,
        builder: (context, state) => loginPageBuilder(context),
      ),
      GoRoute(
        path: ForbiddenRoute.pathPattern,
        name: ForbiddenRoute.name,
        builder: (context, state) => const ForbiddenPage(),
      ),
    ],
    errorBuilder: (context, state) => const NotFoundPage(),
  );

  String? _redirect(BuildContext context, GoRouterState state) {
    final authRedirect = authGuard.redirect(context, state);
    if (authRedirect != null) return authRedirect;

    return organizationGuard.redirect(context, state);
  }
}
