import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vestipro/core/navigation/navigation.dart';

void main() {
  group('AppRouter', () {
    testWidgets('shows the not found page for an unknown path', (tester) async {
      final appRouter = _buildRouter();

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: appRouter.router),
      );
      appRouter.router.go('/this-path-does-not-exist');
      await tester.pumpAndSettle();

      expect(find.text('Página não encontrada'), findsOneWidget);
    });

    testWidgets('shows the forbidden page when a guard denies access', (
      tester,
    ) async {
      final appRouter = _buildRouter(authGuard: const _DenyOrgRoutesGuard());

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: appRouter.router),
      );
      appRouter.router.go(const AboutAppRoute(orgId: 'acme').location);
      await tester.pumpAndSettle();

      expect(find.text('Sem permissão'), findsOneWidget);
    });

    testWidgets('resolves the orgId path parameter for the example module', (
      tester,
    ) async {
      String? capturedOrgId;
      final appRouter = _buildRouter(
        aboutAppPageBuilder: (context, orgId) {
          capturedOrgId = orgId;
          return Scaffold(body: Text('about-app:$orgId'));
        },
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: appRouter.router),
      );
      appRouter.router.go(const AboutAppRoute(orgId: 'acme-fashion').location);
      await tester.pumpAndSettle();

      expect(capturedOrgId, 'acme-fashion');
      expect(find.text('about-app:acme-fashion'), findsOneWidget);
    });

    testWidgets('allows navigation by default (stub guards)', (tester) async {
      final appRouter = _buildRouter();

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: appRouter.router),
      );
      appRouter.router.go(const AboutAppRoute(orgId: 'acme').location);
      await tester.pumpAndSettle();

      expect(find.text('about-app:acme'), findsOneWidget);
      expect(find.text('Sem permissão'), findsNothing);
    });

    testWidgets('renders the injected login page at LoginRoute (TASK-034)', (
      tester,
    ) async {
      final appRouter = _buildRouter(
        loginPageBuilder: (context) => const Scaffold(body: Text('login-page')),
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: appRouter.router),
      );
      appRouter.router.go(const LoginRoute().location);
      await tester.pumpAndSettle();

      expect(find.text('login-page'), findsOneWidget);
    });
  });
}

AppRouter _buildRouter({
  AuthGuard? authGuard,
  ActiveOrganizationGuard? organizationGuard,
  Widget Function(BuildContext context, String orgId)? aboutAppPageBuilder,
  WidgetBuilder? loginPageBuilder,
}) {
  return AppRouter(
    authGuard: authGuard,
    organizationGuard: organizationGuard,
    aboutAppPageBuilder:
        aboutAppPageBuilder ??
        (context, orgId) => Scaffold(body: Text('about-app:$orgId')),
    loginPageBuilder:
        loginPageBuilder ?? (context) => const Scaffold(body: Text('login')),
    signUpPageBuilder: (context) => const Scaffold(body: Text('sign-up')),
    forgotPasswordPageBuilder: (context) =>
        const Scaffold(body: Text('forgot-password')),
    onboardingWizardPageBuilder: (context) =>
        const Scaffold(body: Text('onboarding-wizard')),
  );
}

final class _DenyOrgRoutesGuard implements AuthGuard {
  const _DenyOrgRoutesGuard();

  @override
  String? redirect(BuildContext context, GoRouterState state) {
    if (state.uri.path.startsWith('/org/')) {
      return const ForbiddenRoute().location;
    }
    return null;
  }
}
