import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/auth/auth.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/navigation/navigation.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/authentication/domain/usecases/send_password_reset_email_use_case.dart';
import 'package:vestipro/features/authentication/presentation/bloc/forgot_password_bloc.dart';
import 'package:vestipro/features/authentication/presentation/bloc/forgot_password_state.dart';
import 'package:vestipro/features/authentication/presentation/pages/forgot_password_page.dart';

const _validEmail = 'vendedor@vestipro.com.br';

void main() {
  group('ForgotPasswordPage', () {
    testWidgets(
      'rejects an empty submission locally without calling the repository',
      (tester) async {
        final authRepository = _AuthRepositoryStub(
          result: const AppSuccess<void>(null),
        );
        await tester.pumpWidget(_buildApp(authRepository));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Enviar instruções'));
        await tester.pumpAndSettle();

        expect(find.text('Informe seu e-mail.'), findsOneWidget);
        expect(authRepository.callCount, 0);
      },
    );

    testWidgets(
      'shows a loading state on submit and blocks a second tap while the '
      'first request is still in flight',
      (tester) async {
        final completer = Completer<AppResult<void>>();
        final authRepository = _AuthRepositoryStub(
          pendingResult: completer.future,
        );
        await tester.pumpWidget(_buildApp(authRepository));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.bySemanticsLabel('Campo de e-mail'),
          _validEmail,
        );
        await tester.pump();

        await tester.tap(find.text('Enviar instruções'));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // A second tap while submitting must not trigger a second call.
        await tester.tap(find.text('Enviar instruções'), warnIfMissed: false);
        await tester.pump();

        completer.complete(const AppSuccess<void>(null));
        await tester.pumpAndSettle();

        expect(authRepository.callCount, 1);
      },
    );

    testWidgets(
      'shows the exact same generic message for an existing account as for '
      'an unknown one (never reveals whether the account exists)',
      (tester) async {
        for (final result in <AppResult<void>>[
          const AppSuccess<void>(null),
          const AppFailure<void>(
            AuthenticationFailure(
              'E-mail ou senha inválidos.',
              code: 'user-not-found',
            ),
          ),
        ]) {
          final authRepository = _AuthRepositoryStub(result: result);
          await tester.pumpWidget(_buildApp(authRepository));
          await tester.pumpAndSettle();

          await tester.enterText(
            find.bySemanticsLabel('Campo de e-mail'),
            _validEmail,
          );
          await tester.pump();

          await tester.tap(find.text('Enviar instruções'));
          await tester.pumpAndSettle();

          expect(find.text(kPasswordResetGenericMessage), findsOneWidget);
        }
      },
    );

    testWidgets('shows a friendly message for a connectivity failure without '
        'clearing the typed e-mail', (tester) async {
      final authRepository = _AuthRepositoryStub(
        result: const AppFailure<void>(
          ConnectivityFailure('Sem conexão com a internet.'),
        ),
      );
      await tester.pumpWidget(_buildApp(authRepository));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.bySemanticsLabel('Campo de e-mail'),
        _validEmail,
      );
      await tester.pump();

      await tester.tap(find.text('Enviar instruções'));
      await tester.pumpAndSettle();

      expect(find.text('Sem conexão com a internet.'), findsOneWidget);
      expect(find.text(_validEmail), findsOneWidget);
    });

    testWidgets('navigates back to the login route', (tester) async {
      await tester.pumpWidget(
        _buildApp(_AuthRepositoryStub(result: const AppSuccess<void>(null))),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Voltar para o login'));
      await tester.pumpAndSettle();

      expect(find.text('login-page'), findsOneWidget);
    });
  });
}

Widget _buildApp(_AuthRepositoryStub authRepository) {
  final router = GoRouter(
    initialLocation: const PasswordResetRoute().location,
    routes: <RouteBase>[
      GoRoute(
        path: PasswordResetRoute.pathPattern,
        name: PasswordResetRoute.name,
        builder: (context, state) => ForgotPasswordPage(
          createBloc: () => ForgotPasswordBloc(
            sendPasswordResetEmail: SendPasswordResetEmailUseCase(
              authRepository,
            ),
            analyticsService: FakeAnalyticsService(),
          ),
        ),
      ),
      GoRoute(
        path: LoginRoute.pathPattern,
        name: LoginRoute.name,
        builder: (context, state) => const Scaffold(body: Text('login-page')),
      ),
    ],
  );

  return MaterialApp.router(theme: AppTheme.light, routerConfig: router);
}

final class _AuthRepositoryStub implements AuthRepository {
  _AuthRepositoryStub({this.result, this.pendingResult})
    : assert(
        result != null || pendingResult != null,
        'Provide either a ready result or a pendingResult.',
      );

  final AppResult<void>? result;
  final Future<AppResult<void>>? pendingResult;
  int callCount = 0;

  @override
  Stream<SessionUser?> get authStateChanges =>
      const Stream<SessionUser?>.empty();

  @override
  SessionUser? get currentUser => null;

  @override
  Future<AppResult<SessionUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
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
  Future<AppResult<void>> sendPasswordResetEmail({
    required String email,
  }) async {
    callCount++;
    if (pendingResult != null) {
      return pendingResult!;
    }
    return result!;
  }
}
