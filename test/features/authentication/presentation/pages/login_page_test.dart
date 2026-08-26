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
import 'package:vestipro/features/organizations/organizations.dart';

const _validEmail = 'vendedor@vestipro.com.br';
const _validPassword = 'super-secret';
const _signedInUser = SessionUser(uid: 'user-1', emailVerified: true);

final _ownedMembership = Membership(
  id: 'user-1',
  organizationId: 'org-acme',
  userId: 'user-1',
  roleId: 'OWNER',
  roleName: 'OWNER',
  status: MembershipStatus.active,
  version: 1,
  createdAt: DateTime.utc(2026, 1, 1),
  createdBy: 'user-1',
  updatedAt: DateTime.utc(2026, 1, 1),
  updatedBy: 'user-1',
);

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
        expect(find.text('catalog-home-page:org-acme'), findsOneWidget);
      },
    );

    testWidgets(
      'sends a user with no active Membership yet to onboarding, instead of '
      'a placeholder organization scope',
      (tester) async {
        final authRepository = _AuthRepositoryStub(
          result: const AppSuccess<SessionUser>(_signedInUser),
        );
        await tester.pumpWidget(
          _buildApp(authRepository, activeMemberships: const <Membership>[]),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.bySemanticsLabel('Campo de e-mail'),
          _validEmail,
        );
        await tester.enterText(
          find.bySemanticsLabel('Campo de senha'),
          _validPassword,
        );
        await tester.tap(find.text('Entrar'));
        await tester.pumpAndSettle();

        expect(find.text('onboarding-wizard-page'), findsOneWidget);
      },
    );

    testWidgets('returns to the originally requested route after login', (
      tester,
    ) async {
      final authRepository = _AuthRepositoryStub(
        result: const AppSuccess<SessionUser>(_signedInUser),
      );
      await tester.pumpWidget(
        _buildApp(
          authRepository,
          initialLocation: LoginRoute(
            returnTo: const CatalogHomeRoute(
              orgId: 'acme',
              companyId: 'company-1',
            ).location,
          ).location,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.bySemanticsLabel('Campo de e-mail'),
        _validEmail,
      );
      await tester.enterText(
        find.bySemanticsLabel('Campo de senha'),
        _validPassword,
      );
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.text('catalog-home-page:acme:company-1'), findsOneWidget);
    });

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
        expect(find.textContaining('catalog-home-page'), findsNothing);
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

    testWidgets('navigates to the sign-up route via "Criar conta"', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          _AuthRepositoryStub(
            result: const AppSuccess<SessionUser>(_signedInUser),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Criar conta'));
      await tester.pumpAndSettle();

      expect(find.text('sign-up-page'), findsOneWidget);
    });

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

Widget _buildApp(
  AuthRepositoryStub authRepository, {
  String? initialLocation,
  List<Membership>? activeMemberships,
}) {
  final router = GoRouter(
    initialLocation: initialLocation ?? const LoginRoute().location,
    routes: <RouteBase>[
      GoRoute(
        path: LoginRoute.pathPattern,
        name: LoginRoute.name,
        builder: (context, state) => LoginPage(
          createBloc: () => LoginBloc(
            signInWithEmailAndPassword: SignInWithEmailAndPasswordUseCase(
              authRepository,
            ),
            resolveActiveOrganizationId: ResolveActiveOrganizationIdUseCase(
              _MembershipRepositoryStub(
                activeMemberships ?? <Membership>[_ownedMembership],
              ),
            ),
            analyticsService: FakeAnalyticsService(),
          ),
        ),
      ),
      GoRoute(
        path: CatalogHomeRoute.pathPattern,
        name: CatalogHomeRoute.name,
        builder: (context, state) {
          final companyId = state.uri.queryParameters['companyId'];
          return Scaffold(
            body: Text(
              'catalog-home-page:${state.pathParameters['orgId']}'
              '${companyId == null ? '' : ':$companyId'}',
            ),
          );
        },
      ),
      GoRoute(
        path: OnboardingWizardRoute.pathPattern,
        name: OnboardingWizardRoute.name,
        builder: (context, state) =>
            const Scaffold(body: Text('onboarding-wizard-page')),
      ),
      GoRoute(
        path: PasswordResetRoute.pathPattern,
        name: PasswordResetRoute.name,
        builder: (context, state) =>
            const Scaffold(body: Text('password-reset-page')),
      ),
      GoRoute(
        path: SignUpRoute.pathPattern,
        name: SignUpRoute.name,
        builder: (context, state) => const Scaffold(body: Text('sign-up-page')),
      ),
    ],
  );

  return MaterialApp.router(theme: AppTheme.light, routerConfig: router);
}

final class _MembershipRepositoryStub implements MembershipRepository {
  const _MembershipRepositoryStub(this.activeMemberships);

  final List<Membership> activeMemberships;

  @override
  Future<AppResult<List<Membership>>> listActiveByUser(String userId) async {
    return AppSuccess<List<Membership>>(activeMemberships);
  }

  @override
  Future<AppResult<Membership>> create({
    required String organizationId,
    required String userId,
    required String roleId,
    required String roleName,
    List<String> teamIds = const <String>[],
    required String createdBy,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<Membership>> getByUser({
    required String organizationId,
    required String userId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<List<Membership>>> listByOrganization(
    String organizationId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<Membership>> update({
    required String organizationId,
    required String userId,
    required String roleId,
    required String roleName,
    required List<String> teamIds,
    required MembershipStatus status,
    required String updatedBy,
  }) {
    throw UnimplementedError();
  }
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
