import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/auth/auth.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/navigation/navigation.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/authentication/domain/entities/user_profile.dart';
import 'package:vestipro/features/authentication/domain/repositories/user_profile_repository.dart';
import 'package:vestipro/features/authentication/domain/usecases/create_account_with_email_and_password_use_case.dart';
import 'package:vestipro/features/authentication/presentation/bloc/sign_up_bloc.dart';
import 'package:vestipro/features/invites/invites.dart';
import 'package:vestipro/features/organizations/organizations.dart';

const _invitedEmail = 'convidado@vestipro.com.br';
const _validPreview = InvitePreview(
  outcome: InviteAcceptanceOutcome.valid,
  organizationId: 'org-1',
  organizationName: 'Grupo Fashion XPTO',
  email: _invitedEmail,
  roleName: SystemRoleName.salesRep,
);
const _acceptedInvite = AcceptedInvite(
  organizationId: 'org-1',
  organizationName: 'Grupo Fashion XPTO',
  roleName: SystemRoleName.salesRep,
);

void main() {
  group('AcceptInvitePage', () {
    testWidgets(
      'shows a specific message for an expired invite, never a raw error',
      (tester) async {
        final inviteRepository = _InviteAcceptanceRepositoryStub(
          validateResult: const AppSuccess(
            InvitePreview(outcome: InviteAcceptanceOutcome.expired),
          ),
        );
        await tester.pumpWidget(
          _buildApp(
            inviteRepository: inviteRepository,
            authRepository: _AuthRepositoryStub(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Convite expirado'), findsOneWidget);
      },
    );

    testWidgets(
      'creates a brand-new account with the e-mail locked to the invite, '
      'then accepts and navigates to the joined organization',
      (tester) async {
        final authRepository = _AuthRepositoryStub();
        final inviteRepository = _InviteAcceptanceRepositoryStub(
          validateResult: const AppSuccess(_validPreview),
          acceptResult: const AppSuccess(_acceptedInvite),
        );
        await tester.pumpWidget(
          _buildApp(
            inviteRepository: inviteRepository,
            authRepository: authRepository,
          ),
        );
        await tester.pumpAndSettle();

        // The e-mail field is pre-filled and locked.
        expect(find.text(_invitedEmail), findsOneWidget);

        await tester.enterText(
          find.bySemanticsLabel('Campo de nome'),
          'Ana Souza',
        );
        await tester.enterText(
          find.bySemanticsLabel('Campo de senha'),
          'senha123',
        );
        await tester.enterText(
          find.bySemanticsLabel('Campo de confirmação de senha'),
          'senha123',
        );
        await tester.ensureVisible(find.byType(Checkbox));
        await tester.tap(find.byType(Checkbox));
        await tester.pump();

        await tester.ensureVisible(find.text('Criar conta'));
        await tester.tap(find.text('Criar conta'));
        await tester.pumpAndSettle();

        expect(authRepository.createAccountCallCount, 1);
        expect(inviteRepository.acceptCallCount, 1);
        expect(find.text('catalog-home-page:org-1'), findsOneWidget);
      },
    );

    testWidgets(
      'confirms directly when already signed in with a matching e-mail',
      (tester) async {
        final authRepository = _AuthRepositoryStub(
          currentUser: const SessionUser(
            uid: 'user-1',
            email: _invitedEmail,
            emailVerified: true,
          ),
        );
        final inviteRepository = _InviteAcceptanceRepositoryStub(
          validateResult: const AppSuccess(_validPreview),
          acceptResult: const AppSuccess(_acceptedInvite),
        );
        await tester.pumpWidget(
          _buildApp(
            inviteRepository: inviteRepository,
            authRepository: authRepository,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Aceitar convite'), findsOneWidget);
        await tester.tap(find.text('Aceitar convite'));
        await tester.pumpAndSettle();

        expect(inviteRepository.acceptCallCount, 1);
        expect(find.text('catalog-home-page:org-1'), findsOneWidget);
      },
    );

    testWidgets(
      'blocks and steers to sign-out when the signed-in e-mail diverges '
      'from the invite',
      (tester) async {
        final authRepository = _AuthRepositoryStub(
          currentUser: const SessionUser(
            uid: 'user-1',
            email: 'outro@vestipro.com.br',
            emailVerified: true,
          ),
        );
        final inviteRepository = _InviteAcceptanceRepositoryStub(
          validateResult: const AppSuccess(_validPreview),
        );
        await tester.pumpWidget(
          _buildApp(
            inviteRepository: inviteRepository,
            authRepository: authRepository,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('E-mail diferente do convite'), findsOneWidget);
        expect(find.text('Aceitar convite'), findsNothing);

        await tester.tap(find.text('Sair e continuar'));
        await tester.pumpAndSettle();

        expect(authRepository.signOutCallCount, 1);
        // Session cleared client-side: falls back to the "brand-new
        // account" flow, still locked to the invite's own e-mail.
        expect(find.text(_invitedEmail), findsOneWidget);
      },
    );
  });
}

Widget _buildApp({
  required _InviteAcceptanceRepositoryStub inviteRepository,
  required _AuthRepositoryStub authRepository,
}) {
  final userProfileRepository = _UserProfileRepositoryStub();

  final router = GoRouter(
    initialLocation: const InviteAcceptanceRoute(token: 'token-123').location,
    routes: <RouteBase>[
      GoRoute(
        path: InviteAcceptanceRoute.pathPattern,
        name: InviteAcceptanceRoute.name,
        builder: (context, state) => AcceptInvitePage(
          token: state.pathParameters['token']!,
          createBloc: () => AcceptInviteBloc(
            validateInvite: ValidateInviteUseCase(inviteRepository),
            acceptInvite: AcceptInviteUseCase(inviteRepository),
            authRepository: authRepository,
            analyticsService: FakeAnalyticsService(),
          ),
          createSignUpBloc: () => SignUpBloc(
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
        path: CatalogHomeRoute.pathPattern,
        name: CatalogHomeRoute.name,
        builder: (context, state) => Scaffold(
          body: Text('catalog-home-page:${state.pathParameters['orgId']}'),
        ),
      ),
    ],
  );

  return MaterialApp.router(theme: AppTheme.light, routerConfig: router);
}

final class _InviteAcceptanceRepositoryStub
    implements InviteAcceptanceRepository {
  _InviteAcceptanceRepositoryStub({this.validateResult, this.acceptResult});

  final AppResult<InvitePreview>? validateResult;
  final AppResult<AcceptedInvite>? acceptResult;
  int acceptCallCount = 0;

  @override
  Future<AppResult<InvitePreview>> validate({required String token}) async {
    return validateResult!;
  }

  @override
  Future<AppResult<AcceptedInvite>> accept({required String token}) async {
    acceptCallCount++;
    return acceptResult!;
  }
}

final class _AuthRepositoryStub implements AuthRepository {
  _AuthRepositoryStub({this.currentUser});

  @override
  SessionUser? currentUser;
  int createAccountCallCount = 0;
  int signOutCallCount = 0;

  @override
  Stream<SessionUser?> get authStateChanges =>
      const Stream<SessionUser?>.empty();

  @override
  Future<AppResult<SessionUser>> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    createAccountCallCount++;
    final created = SessionUser(
      uid: 'new-user-1',
      email: email,
      emailVerified: false,
    );
    currentUser = created;
    return AppSuccess<SessionUser>(created);
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
  Future<AppResult<void>> signOut() async {
    signOutCallCount++;
    currentUser = null;
    return const AppSuccess<void>(null);
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

final class _UserProfileRepositoryStub implements UserProfileRepository {
  @override
  Future<AppResult<void>> createInitialProfile(UserProfile profile) async {
    return const AppSuccess<void>(null);
  }
}
