import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/auth/auth.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/navigation/navigation.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/authentication/domain/usecases/sign_in_with_email_and_password_use_case.dart';
import 'package:vestipro/features/authentication/presentation/bloc/login_bloc.dart';
import 'package:vestipro/features/authentication/presentation/pages/login_page.dart';

const _validEmail = 'vendedor@vestipro.com.br';
const _validPassword = 'super-secret';
const _signedInUser = SessionUser(uid: 'user-1', emailVerified: true);

void main() {
  group('LoginPage', () {
    testWidgets('shows persistent labels for e-mail and password, even '
        'after typing', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          _AuthRepositoryStub(
            result: const AppSuccess<SessionUser>(_signedInUser),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.bySemanticsLabel('Campo de e-mail'),
        _validEmail,
      );
      await tester.pump();

      expect(find.bySemanticsLabel('Campo de e-mail'), findsOneWidget);
      expect(find.bySemanticsLabel('Campo de senha'), findsOneWidget);
      expect(find.text(_validEmail), findsOneWidget);
    });

    testWidgets(
      'rejects an empty submission locally without calling the repository',
      (tester) async {
        final authRepository = _AuthRepositoryStub(
          result: const AppSuccess<SessionUser>(_signedInUser),
        );
        await tester.pumpWidget(_buildApp(authRepository));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Entrar'));
        await tester.pumpAndSettle();

        expect(find.text('Informe seu e-mail.'), findsOneWidget);
        expect(find.text('Informe sua senha.'), findsOneWidget);
        expect(authRepository.signInCallCount, 0);
      },
    );

    testWidgets(
      'shows a loading state on submit and blocks a second tap while the '
      'first sign-in is still in flight',
      (tester) async {
        final completer = Completer<AppResult<SessionUser>>();
        final authRepository = _AuthRepositoryStub(
          pendingResult: completer.future,
        );
        await tester.pumpWidget(_buildApp(authRepository));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.bySemanticsLabel('Campo de e-mail'),
          _validEmail,
        );
        await tester.enterText(
          find.bySemanticsLabel('Campo de senha'),
          _validPassword,
        );
        await tester.pump();

        await tester.tap(find.text('Entrar'));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // A second tap while submitting must not trigger a second call.
        await tester.tap(find.text('Entrar'), warnIfMissed: false);
        await tester.pump();

        completer.complete(const AppSuccess<SessionUser>(_signedInUser));
        await tester.pumpAndSettle();

        expect(authRepository.signInCallCount, 1);
        expect(find.text('about-app-page'), findsOneWidget);
      },
    );

    testWidgets(
      'shows a generic error message without clearing the typed fields',
      (tester) async {
        final authRepository = _AuthRepositoryStub(
          result: const AppFailure<SessionUser>(
            AuthenticationFailure('E-mail ou senha inválidos.'),
          ),
        );
        await tester.pumpWidget(_buildApp(authRepository));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.bySemanticsLabel('Campo de e-mail'),
          _validEmail,
        );
        await tester.enterText(
          find.bySemanticsLabel('Campo de senha'),
          'wrong-password',
        );
        await tester.pump();

        await tester.tap(find.text('Entrar'));
        await tester.pumpAndSettle();

        expect(find.text('E-mail ou senha inválidos.'), findsOneWidget);
        expect(find.text(_validEmail), findsOneWidget);
        expect(find.text('about-app-page'), findsNothing);
      },
    );

    testWidgets('toggles the password visibility icon', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          _AuthRepositoryStub(
            result: const AppSuccess<SessionUser>(_signedInUser),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final passwordField = find.bySemanticsLabel('Campo de senha');
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: passwordField,
                matching: find.byType(TextField),
              ),
            )
            .obscureText,
        isTrue,
      );
      expect(find.byTooltip('Mostrar senha'), findsOneWidget);

      await tester.tap(find.byTooltip('Mostrar senha'));
      await tester.pump();

      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: passwordField,
                matching: find.byType(TextField),
              ),
            )
            .obscureText,
        isFalse,
      );
      expect(find.byTooltip('Ocultar senha'), findsOneWidget);
    });

    testWidgets(
      'navigates to the password reset route via "Esqueci minha senha"',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(
            _AuthRepositoryStub(
              result: const AppSuccess<SessionUser>(_signedInUser),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Esqueci minha senha'));
        await tester.pumpAndSettle();

        expect(find.text('password-reset-page'), findsOneWidget);
      },
    );

    testWidgets(
      'moves focus from e-mail to password with Tab (Web keyboard nav)',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(
            _AuthRepositoryStub(
              result: const AppSuccess<SessionUser>(_signedInUser),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.bySemanticsLabel('Campo de e-mail'));
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        final passwordEditable = tester.widget<EditableText>(
          find.descendant(
            of: find.bySemanticsLabel('Campo de senha'),
            matching: find.byType(EditableText),
          ),
        );
        expect(passwordEditable.focusNode.hasFocus, isTrue);
      },
    );
  });
}

Widget _buildApp(AuthRepositoryStub authRepository) {
  final router = GoRouter(
    initialLocation: const LoginRoute().location,
    routes: <RouteBase>[
      GoRoute(
        path: LoginRoute.pathPattern,
        name: LoginRoute.name,
        builder: (context, state) => LoginPage(
          createBloc: () => LoginBloc(
            signInWithEmailAndPassword: SignInWithEmailAndPasswordUseCase(
              authRepository,
            ),
            analyticsService: FakeAnalyticsService(),
          ),
        ),
      ),
      GoRoute(
        path: AboutAppRoute.pathPattern,
        name: AboutAppRoute.name,
        builder: (context, state) =>
            const Scaffold(body: Text('about-app-page')),
      ),
      GoRoute(
        path: PasswordResetRoute.pathPattern,
        name: PasswordResetRoute.name,
        builder: (context, state) =>
            const Scaffold(body: Text('password-reset-page')),
      ),
    ],
  );

  return MaterialApp.router(theme: AppTheme.light, routerConfig: router);
}

typedef AuthRepositoryStub = _AuthRepositoryStub;

final class _AuthRepositoryStub implements AuthRepository {
  _AuthRepositoryStub({this.result, this.pendingResult})
    : assert(
        result != null || pendingResult != null,
        'Provide either a ready result or a pendingResult.',
      );

  final AppResult<SessionUser>? result;
  final Future<AppResult<SessionUser>>? pendingResult;
  int signInCallCount = 0;

  @override
  Stream<SessionUser?> get authStateChanges =>
      const Stream<SessionUser?>.empty();

  @override
  SessionUser? get currentUser => null;

  @override
  Future<AppResult<SessionUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    signInCallCount++;
    if (pendingResult != null) {
      return pendingResult!;
    }
    return result!;
  }

  @override
  Future<AppResult<SessionUser>> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<SessionUser>> signInWithProvider(AuthProviderType provider) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<void>> signOut() {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<void>> sendPasswordResetEmail({required String email}) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<void>> refreshSession() {
    throw UnimplementedError();
  }
}
