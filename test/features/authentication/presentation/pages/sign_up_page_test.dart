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
import 'package:vestipro/features/authentication/domain/entities/user_profile.dart';
import 'package:vestipro/features/authentication/domain/repositories/user_profile_repository.dart';
import 'package:vestipro/features/authentication/domain/usecases/create_account_with_email_and_password_use_case.dart';
import 'package:vestipro/features/authentication/presentation/bloc/sign_up_bloc.dart';
import 'package:vestipro/features/authentication/presentation/pages/sign_up_page.dart';

const _validName = 'Ana Souza';
const _validEmail = 'ana@vestipro.com.br';
const _validPassword = 'senha123';
const _signedUpUser = SessionUser(uid: 'user-1', emailVerified: false);

void main() {
  group('SignUpPage', () {
    testWidgets('blocks submission while the terms checkbox is unchecked', (
      tester,
    ) async {
      final authRepository = _AuthRepositoryStub(
        result: const AppSuccess<SessionUser>(_signedUpUser),
      );
      await tester.pumpWidget(_buildApp(authRepository));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.bySemanticsLabel('Campo de nome'),
        _validName,
      );
      await tester.enterText(
        find.bySemanticsLabel('Campo de e-mail'),
        _validEmail,
      );
      await tester.enterText(
        find.bySemanticsLabel('Campo de senha'),
        _validPassword,
      );
      await tester.enterText(
        find.bySemanticsLabel('Campo de confirmação de senha'),
        _validPassword,
      );
      await tester.pump();

      await tester.tap(find.text('Criar conta'));
      await tester.pumpAndSettle();

      expect(authRepository.createAccountCallCount, 0);
      expect(find.text('about-app-page'), findsNothing);
    });

    testWidgets(
      'accepting the terms checkbox enables submission and creates the '
      'account',
      (tester) async {
        final authRepository = _AuthRepositoryStub(
          result: const AppSuccess<SessionUser>(_signedUpUser),
        );
        await tester.pumpWidget(_buildApp(authRepository));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.bySemanticsLabel('Campo de nome'),
          _validName,
        );
        await tester.enterText(
          find.bySemanticsLabel('Campo de e-mail'),
          _validEmail,
        );
        await tester.enterText(
          find.bySemanticsLabel('Campo de senha'),
          _validPassword,
        );
        await tester.enterText(
          find.bySemanticsLabel('Campo de confirmação de senha'),
          _validPassword,
        );
        await tester.tap(find.byType(Checkbox));
        await tester.pump();

        await tester.tap(find.text('Criar conta'));
        await tester.pumpAndSettle();

        expect(authRepository.createAccountCallCount, 1);
        expect(find.text('onboarding-wizard-page'), findsOneWidget);
      },
    );

    testWidgets(
      'rejects mismatched passwords locally without calling the repository',
      (tester) async {
        final authRepository = _AuthRepositoryStub(
          result: const AppSuccess<SessionUser>(_signedUpUser),
        );
        await tester.pumpWidget(_buildApp(authRepository));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.bySemanticsLabel('Campo de nome'),
          _validName,
        );
        await tester.enterText(
          find.bySemanticsLabel('Campo de e-mail'),
          _validEmail,
        );
        await tester.enterText(
          find.bySemanticsLabel('Campo de senha'),
          _validPassword,
        );
        await tester.enterText(
          find.bySemanticsLabel('Campo de confirmação de senha'),
          'outra-senha1',
        );
        await tester.tap(find.byType(Checkbox));
        await tester.pump();

        await tester.tap(find.text('Criar conta'));
        await tester.pumpAndSettle();

        expect(find.text('As senhas não coincidem.'), findsOneWidget);
        expect(authRepository.createAccountCallCount, 0);
      },
    );

    testWidgets(
      'shows a loading state on submit and blocks a second tap while the '
      'first request is still in flight',
      (tester) async {
        final completer = Completer<AppResult<SessionUser>>();
        final authRepository = _AuthRepositoryStub(
          pendingResult: completer.future,
        );
        await tester.pumpWidget(_buildApp(authRepository));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.bySemanticsLabel('Campo de nome'),
          _validName,
        );
        await tester.enterText(
          find.bySemanticsLabel('Campo de e-mail'),
          _validEmail,
        );
        await tester.enterText(
          find.bySemanticsLabel('Campo de senha'),
          _validPassword,
        );
        await tester.enterText(
          find.bySemanticsLabel('Campo de confirmação de senha'),
          _validPassword,
        );
        await tester.tap(find.byType(Checkbox));
        await tester.pump();

        await tester.tap(find.text('Criar conta'));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.tap(find.text('Criar conta'), warnIfMissed: false);
        await tester.pump();

        completer.complete(const AppSuccess<SessionUser>(_signedUpUser));
        await tester.pumpAndSettle();

        expect(authRepository.createAccountCallCount, 1);
        expect(find.text('onboarding-wizard-page'), findsOneWidget);
      },
    );

    testWidgets(
      'shows a generic error message without clearing the typed fields',
      (tester) async {
        final authRepository = _AuthRepositoryStub(
          result: const AppFailure<SessionUser>(
            ConflictFailure('Este e-mail já está em uso.'),
          ),
        );
        await tester.pumpWidget(_buildApp(authRepository));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.bySemanticsLabel('Campo de nome'),
          _validName,
        );
        await tester.enterText(
          find.bySemanticsLabel('Campo de e-mail'),
          _validEmail,
        );
        await tester.enterText(
          find.bySemanticsLabel('Campo de senha'),
          _validPassword,
        );
        await tester.enterText(
          find.bySemanticsLabel('Campo de confirmação de senha'),
          _validPassword,
        );
        await tester.tap(find.byType(Checkbox));
        await tester.pump();

        await tester.tap(find.text('Criar conta'));
        await tester.pumpAndSettle();

        expect(find.text('Este e-mail já está em uso.'), findsOneWidget);
        expect(find.text(_validEmail), findsOneWidget);
        expect(find.text('onboarding-wizard-page'), findsNothing);
      },
    );

    testWidgets(
      'navigates back to the login route via "Já tem conta? Entrar"',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(
            _AuthRepositoryStub(
              result: const AppSuccess<SessionUser>(_signedUpUser),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // The form is taller than the default test viewport (it is
        // scrollable in `SignUpView`'s `SingleChildScrollView`), so the link
        // below the submit button needs to be scrolled into view first.
        await tester.ensureVisible(find.text('Já tem conta? Entrar'));
        await tester.tap(find.text('Já tem conta? Entrar'));
        await tester.pumpAndSettle();

        expect(find.text('login-page'), findsOneWidget);
      },
    );
  });
}

Widget _buildApp(_AuthRepositoryStub authRepository) {
  final userProfileRepository = _UserProfileRepositoryStub();

  final router = GoRouter(
    initialLocation: const SignUpRoute().location,
    routes: <RouteBase>[
      GoRoute(
        path: SignUpRoute.pathPattern,
        name: SignUpRoute.name,
        builder: (context, state) => SignUpPage(
          createBloc: () => SignUpBloc(
            createAccountWithEmailAndPassword:
                CreateAccountWithEmailAndPasswordUseCase(
                  authRepository,
                  userProfileRepository,
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
      GoRoute(
        path: OnboardingWizardRoute.pathPattern,
        name: OnboardingWizardRoute.name,
        builder: (context, state) =>
            const Scaffold(body: Text('onboarding-wizard-page')),
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

  final AppResult<SessionUser>? result;
  final Future<AppResult<SessionUser>>? pendingResult;
  int createAccountCallCount = 0;

  @override
  Stream<SessionUser?> get authStateChanges =>
      const Stream<SessionUser?>.empty();

  @override
  SessionUser? get currentUser => null;

  @override
  Future<AppResult<SessionUser>> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    createAccountCallCount++;
    if (pendingResult != null) {
      return pendingResult!;
    }
    return result!;
  }

  @override
  Future<AppResult<SessionUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<SessionUser>> signInWithProvider(AuthProviderType provider) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<void>> signOut() async => const AppSuccess<void>(null);

  @override
  Future<AppResult<void>> sendPasswordResetEmail({required String email}) {
    throw UnimplementedError();
  }
}

final class _UserProfileRepositoryStub implements UserProfileRepository {
  @override
  Future<AppResult<void>> createInitialProfile(UserProfile profile) async {
    return const AppSuccess<void>(null);
  }
}
