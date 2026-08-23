import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/auth/auth.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/navigation/navigation.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/onboarding/domain/entities/onboarding_progress.dart';
import 'package:vestipro/features/onboarding/domain/repositories/onboarding_progress_repository.dart';
import 'package:vestipro/features/onboarding/domain/usecases/clear_onboarding_progress_use_case.dart';
import 'package:vestipro/features/onboarding/domain/usecases/complete_onboarding_use_case.dart';
import 'package:vestipro/features/onboarding/domain/usecases/get_onboarding_progress_use_case.dart';
import 'package:vestipro/features/onboarding/domain/usecases/save_onboarding_progress_use_case.dart';
import 'package:vestipro/features/onboarding/domain/value_objects/onboarding_step.dart';
import 'package:vestipro/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:vestipro/features/onboarding/presentation/pages/onboarding_wizard_page.dart';
import 'package:vestipro/features/organizations/organizations.dart';

const _signedInUser = SessionUser(uid: 'user-1', emailVerified: true);

void main() {
  group('OnboardingWizardPage', () {
    testWidgets(
      'resumes at the saved step with the previously typed organization '
      'name preserved, simulating the app being closed and reopened',
      (tester) async {
        final progressRepository = _OnboardingProgressRepositoryStub();
        progressRepository.saved['user-1'] = const OnboardingProgress(
          step: OnboardingStep.segment,
          organizationName: 'Grupo Fashion XPTO',
        );

        await tester.pumpWidget(
          _buildApp(
            progressRepository: progressRepository,
            organizationRepository: _OrganizationRepositoryStub(),
          ),
        );
        await tester.pumpAndSettle();

        // Resumed directly on the segment step (step 2), not step 1.
        expect(find.text('Passo 2 de 4'), findsOneWidget);
        expect(find.text('Vestuário'), findsOneWidget);

        // Going back reveals the organization name typed before the app
        // was supposedly closed, still there.
        await tester.tap(find.text('Voltar'));
        await tester.pumpAndSettle();

        expect(find.text('Passo 1 de 4'), findsOneWidget);
        expect(find.text('Grupo Fashion XPTO'), findsOneWidget);
      },
    );

    testWidgets(
      'blocks advancing past the first step without an organization name',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(
            progressRepository: _OnboardingProgressRepositoryStub(),
            organizationRepository: _OrganizationRepositoryStub(),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();

        expect(find.text('Passo 1 de 4'), findsOneWidget);
        expect(find.text('Informe o nome da organização.'), findsOneWidget);
      },
    );

    testWidgets(
      'walks through every step and completes the wizard, navigating away '
      'with the newly created Organization id',
      (tester) async {
        final organization = Organization(
          id: 'org-42',
          name: 'Grupo Fashion XPTO',
          slug: 'grupo-fashion-xpto-11112222',
          settings: const OrganizationSettings(
            currency: 'BRL',
            country: 'BR',
            defaultLanguage: 'pt-BR',
            segment: 'apparel',
          ),
          status: OrganizationStatus.active,
          createdAt: DateTime.utc(2026, 1, 1),
          createdBy: 'user-1',
          updatedAt: DateTime.utc(2026, 1, 1),
          updatedBy: 'user-1',
        );
        final organizationRepository = _OrganizationRepositoryStub(
          result: AppSuccess<Organization>(organization),
        );

        await tester.pumpWidget(
          _buildApp(
            progressRepository: _OnboardingProgressRepositoryStub(),
            organizationRepository: organizationRepository,
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.bySemanticsLabel('Campo de nome da organização'),
          'Grupo Fashion XPTO',
        );
        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Vestuário'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();

        expect(find.text('Passo 3 de 4'), findsOneWidget);
        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();

        expect(find.text('Passo 4 de 4'), findsOneWidget);
        await tester.tap(find.text('Concluir'));
        await tester.pumpAndSettle();

        expect(organizationRepository.createCallCount, 1);
        expect(find.text('about-app-page:org-42'), findsOneWidget);
      },
    );
  });
}

Widget _buildApp({
  required _OnboardingProgressRepositoryStub progressRepository,
  required _OrganizationRepositoryStub organizationRepository,
}) {
  final authRepository = _AuthRepositoryStub(_signedInUser);
  final uuid = _MockUuid();
  when(() => uuid.v4()).thenReturn('00000000-0000-0000-0000-000000000000');

  final router = GoRouter(
    initialLocation: const OnboardingWizardRoute().location,
    routes: <RouteBase>[
      GoRoute(
        path: OnboardingWizardRoute.pathPattern,
        name: OnboardingWizardRoute.name,
        builder: (context, state) => OnboardingWizardPage(
          createBloc: () => OnboardingBloc(
            getProgress: GetOnboardingProgressUseCase(progressRepository),
            saveProgress: SaveOnboardingProgressUseCase(progressRepository),
            clearProgress: ClearOnboardingProgressUseCase(progressRepository),
            completeOnboarding: CompleteOnboardingUseCase.withDependencies(
              CreateOrganizationUseCase(organizationRepository),
              uuid: uuid,
            ),
            authRepository: authRepository,
            analyticsService: FakeAnalyticsService(),
          ),
        ),
      ),
      GoRoute(
        path: AboutAppRoute.pathPattern,
        name: AboutAppRoute.name,
        builder: (context, state) => Scaffold(
          body: Text('about-app-page:${state.pathParameters['orgId']}'),
        ),
      ),
    ],
  );

  return MaterialApp.router(theme: AppTheme.light, routerConfig: router);
}

class _MockUuid extends Mock implements Uuid {}

final class _AuthRepositoryStub implements AuthRepository {
  _AuthRepositoryStub(this.user);

  final SessionUser? user;

  @override
  Stream<SessionUser?> get authStateChanges =>
      const Stream<SessionUser?>.empty();

  @override
  SessionUser? get currentUser => user;

  @override
  Future<AppResult<SessionUser>> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) {
    throw UnimplementedError();
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

  @override
  Future<AppResult<void>> refreshSession() {
    throw UnimplementedError();
  }
}

final class _OnboardingProgressRepositoryStub
    implements OnboardingProgressRepository {
  final Map<String, OnboardingProgress> saved = <String, OnboardingProgress>{};

  @override
  Future<AppResult<OnboardingProgress?>> getProgress({
    required String userId,
  }) async {
    return AppSuccess<OnboardingProgress?>(saved[userId]);
  }

  @override
  Future<AppResult<void>> saveProgress({
    required String userId,
    required OnboardingProgress progress,
  }) async {
    saved[userId] = progress;
    return const AppSuccess<void>(null);
  }

  @override
  Future<AppResult<void>> clearProgress({required String userId}) async {
    saved.remove(userId);
    return const AppSuccess<void>(null);
  }
}

final class _OrganizationRepositoryStub implements OrganizationRepository {
  _OrganizationRepositoryStub({AppResult<Organization>? result})
    : result = result ?? AppSuccess<Organization>(_placeholderOrganization);

  final AppResult<Organization> result;
  int createCallCount = 0;

  @override
  Future<AppResult<Organization>> create({
    required String id,
    required String name,
    required String slug,
    required OrganizationSettings settings,
    required String createdBy,
  }) async {
    createCallCount++;
    return result;
  }

  @override
  Future<AppResult<Organization>> getById(String id) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<Organization>> updateSettings({
    required String id,
    required OrganizationSettings settings,
    required String updatedBy,
  }) {
    throw UnimplementedError();
  }
}

final Organization _placeholderOrganization = Organization(
  id: 'placeholder',
  name: 'placeholder',
  slug: 'placeholder',
  settings: const OrganizationSettings(
    currency: 'BRL',
    country: 'BR',
    defaultLanguage: 'pt-BR',
  ),
  status: OrganizationStatus.active,
  createdAt: DateTime.utc(2026, 1, 1),
  createdBy: 'user-1',
  updatedAt: DateTime.utc(2026, 1, 1),
  updatedBy: 'user-1',
);
