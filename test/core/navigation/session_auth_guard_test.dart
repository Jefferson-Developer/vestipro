import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/auth/auth.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/navigation/navigation.dart';
import 'package:vestipro/core/utils/utils.dart';

class _MockSessionService extends Mock implements SessionService {}

void main() {
  group('SessionAuthGuard', () {
    late _MockSessionService sessionService;
    late SessionAuthGuard guard;

    const signedInUser = SessionUser(uid: 'user-1', emailVerified: true);

    setUp(() {
      sessionService = _MockSessionService();
      guard = SessionAuthGuard(sessionService);
    });

    testWidgets('allows navigation when the session is active', (tester) async {
      when(() => sessionService.currentUser).thenReturn(signedInUser);
      when(
        () => sessionService.ensureSessionIsActive(),
      ).thenAnswer((_) async => const AppSuccess<void>(null));
      final appRouter = _buildRouter(guard);

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: appRouter.router),
      );
      appRouter.router.go(const AboutAppRoute(orgId: 'acme').location);
      await tester.pumpAndSettle();

      expect(find.text('about-app:acme'), findsOneWidget);
    });

    testWidgets('redirects to LoginRoute when no session is signed in', (
      tester,
    ) async {
      when(() => sessionService.currentUser).thenReturn(null);
      final appRouter = _buildRouter(guard);

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: appRouter.router),
      );
      appRouter.router.go(const AboutAppRoute(orgId: 'acme').location);
      await tester.pumpAndSettle();

      expect(find.text('about-app:acme'), findsNothing);
      // LoginRoute has a real GoRoute since TASK-034: the guard redirects
      // to the actual login page instead of falling back to not-found.
      expect(find.text('login-page'), findsOneWidget);
      verifyNever(() => sessionService.ensureSessionIsActive());
    });

    testWidgets(
      'redirects to LoginRoute when the session was revoked remotely',
      (tester) async {
        when(() => sessionService.currentUser).thenReturn(signedInUser);
        when(() => sessionService.ensureSessionIsActive()).thenAnswer(
          (_) async => const AppFailure<void>(
            AuthenticationFailure('Sua sessão foi encerrada.'),
          ),
        );
        final appRouter = _buildRouter(guard);

        await tester.pumpWidget(
          MaterialApp.router(routerConfig: appRouter.router),
        );
        appRouter.router.go(const AboutAppRoute(orgId: 'acme').location);
        await tester.pumpAndSettle();

        expect(find.text('about-app:acme'), findsNothing);
        expect(find.text('login-page'), findsOneWidget);
      },
    );

    testWidgets(
      'does not redirect a request that is already headed to LoginRoute',
      (tester) async {
        when(() => sessionService.currentUser).thenReturn(null);
        final appRouter = _buildRouter(guard);

        await tester.pumpWidget(
          MaterialApp.router(routerConfig: appRouter.router),
        );
        appRouter.router.go(const LoginRoute().location);
        await tester.pumpAndSettle();

        // No redirect loop: the guard lets the already-login-bound request
        // fall straight through to the login page itself.
        expect(find.text('login-page'), findsOneWidget);
      },
    );
  });
}

AppRouter _buildRouter(SessionAuthGuard guard) {
  return AppRouter(
    authGuard: guard,
    aboutAppPageBuilder: (context, orgId) =>
        Scaffold(body: Text('about-app:$orgId')),
    auditLogPageBuilder: (context, orgId) =>
        Scaffold(body: Text('audit-log:$orgId')),
    loginPageBuilder: (context) => const Scaffold(body: Text('login-page')),
    signUpPageBuilder: (context) => const Scaffold(body: Text('sign-up-page')),
    forgotPasswordPageBuilder: (context) =>
        const Scaffold(body: Text('forgot-password-page')),
    onboardingWizardPageBuilder: (context) =>
        const Scaffold(body: Text('onboarding-wizard-page')),
    acceptInvitePageBuilder: (context, token) =>
        Scaffold(body: Text('accept-invite-page:$token')),
  );
}
