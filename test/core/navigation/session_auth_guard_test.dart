import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/auth/auth.dart';
import 'package:vestipro/core/navigation/navigation.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('SessionAuthGuard', () {
    late _MockAuthRepository authRepository;
    late SessionAuthGuard guard;

    const signedInUser = SessionUser(uid: 'user-1', emailVerified: true);

    setUp(() {
      authRepository = _MockAuthRepository();
      guard = SessionAuthGuard(authRepository);
    });

    testWidgets('allows navigation when a session is signed in', (
      tester,
    ) async {
      when(() => authRepository.currentUser).thenReturn(signedInUser);
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
      when(() => authRepository.currentUser).thenReturn(null);
      final appRouter = _buildRouter(guard);

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: appRouter.router),
      );
      appRouter.router.go(const AboutAppRoute(orgId: 'acme').location);
      await tester.pumpAndSettle();

      expect(find.text('about-app:acme'), findsNothing);
      // LoginRoute has no GoRoute yet (TASK-034); the app falls back to the
      // generic not-found page instead of a real login screen.
      expect(find.text('Página não encontrada'), findsOneWidget);
    });

    testWidgets(
      'does not redirect a request that is already headed to LoginRoute',
      (tester) async {
        when(() => authRepository.currentUser).thenReturn(null);
        final appRouter = _buildRouter(guard);

        await tester.pumpWidget(
          MaterialApp.router(routerConfig: appRouter.router),
        );
        appRouter.router.go(const LoginRoute().location);
        await tester.pumpAndSettle();

        // No redirect loop: the guard lets the already-login-bound request
        // fall straight through to the not-found page (no /login GoRoute
        // yet), instead of looping back to itself.
        expect(find.text('Página não encontrada'), findsOneWidget);
      },
    );
  });
}

AppRouter _buildRouter(SessionAuthGuard guard) {
  return AppRouter(
    authGuard: guard,
    aboutAppPageBuilder: (context, orgId) =>
        Scaffold(body: Text('about-app:$orgId')),
  );
}
