import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/auth/auth.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/onboarding/domain/entities/onboarding_progress.dart';
import 'package:vestipro/features/onboarding/domain/repositories/onboarding_progress_repository.dart';
import 'package:vestipro/features/onboarding/domain/usecases/clear_onboarding_progress_use_case.dart';
import 'package:vestipro/features/onboarding/domain/usecases/complete_onboarding_use_case.dart';
import 'package:vestipro/features/onboarding/domain/usecases/get_onboarding_progress_use_case.dart';
import 'package:vestipro/features/onboarding/domain/usecases/save_onboarding_progress_use_case.dart';
import 'package:vestipro/features/onboarding/domain/value_objects/onboarding_step.dart';
import 'package:vestipro/features/onboarding/domain/value_objects/organization_segment.dart';
import 'package:vestipro/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:vestipro/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:vestipro/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockUuid extends Mock implements Uuid {}

void main() {
  const signedInUser = SessionUser(uid: 'user-1', emailVerified: true);

  final createdOrganization = Organization(
    id: 'org-1',
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

  late _AuthRepositoryStub authRepository;
  late _OnboardingProgressRepositoryStub progressRepository;
  late _OrganizationRepositoryStub organizationRepository;
  late FakeAnalyticsService analyticsService;

  OnboardingBloc buildBloc() {
    final uuid = _MockUuid();
    when(() => uuid.v4()).thenReturn('11112222-3333-4444-5555-666677778888');

    return OnboardingBloc(
      getProgress: GetOnboardingProgressUseCase(progressRepository),
      saveProgress: SaveOnboardingProgressUseCase(progressRepository),
      clearProgress: ClearOnboardingProgressUseCase(progressRepository),
      completeOnboarding: CompleteOnboardingUseCase.withDependencies(
        CreateOrganizationUseCase(organizationRepository),
        uuid: uuid,
      ),
      authRepository: authRepository,
      analyticsService: analyticsService,
    );
  }

  setUp(() {
    authRepository = _AuthRepositoryStub(signedInUser);
    progressRepository = _OnboardingProgressRepositoryStub();
    organizationRepository = _OrganizationRepositoryStub(
      AppSuccess<Organization>(_placeholderOrganization),
    );
    analyticsService = FakeAnalyticsService();
  });

  group('OnboardingBloc — started', () {
    blocTest<OnboardingBloc, OnboardingState>(
      'becomes ready with the default fields when there is no saved '
      'progress',
      build: buildBloc,
      act: (bloc) => bloc.add(const OnboardingEvent.started()),
      expect: () => <OnboardingState>[
        const OnboardingState(loadStatus: OnboardingLoadStatus.ready),
      ],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'resumes exactly at the saved step, with every previously typed '
      'field preserved',
      build: buildBloc,
      setUp: () {
        progressRepository.saved['user-1'] = const OnboardingProgress(
          step: OnboardingStep.regionalSettings,
          organizationName: 'Grupo Fashion XPTO',
          segment: OrganizationSegment.apparel,
          currency: 'USD',
          country: 'US',
          defaultLanguage: 'en-US',
        );
      },
      act: (bloc) => bloc.add(const OnboardingEvent.started()),
      expect: () => <OnboardingState>[
        const OnboardingState(
          loadStatus: OnboardingLoadStatus.ready,
          step: OnboardingStep.regionalSettings,
          organizationName: 'Grupo Fashion XPTO',
          segment: OrganizationSegment.apparel,
          currency: 'USD',
          country: 'US',
          defaultLanguage: 'en-US',
        ),
      ],
    );
  });

  group('OnboardingBloc — field edits persist progress', () {
    blocTest<OnboardingBloc, OnboardingState>(
      'updates organizationName and saves the progress',
      build: buildBloc,
      act: (bloc) => bloc.add(
        const OnboardingEvent.organizationNameChanged('Grupo Fashion XPTO'),
      ),
      expect: () => <OnboardingState>[
        const OnboardingState(organizationName: 'Grupo Fashion XPTO'),
      ],
      verify: (_) {
        expect(
          progressRepository.saved['user-1']?.organizationName,
          'Grupo Fashion XPTO',
        );
      },
    );
  });

  group('OnboardingBloc — step navigation and validation', () {
    blocTest<OnboardingBloc, OnboardingState>(
      'blocks advancing past step 1 without a name, without saving progress',
      build: buildBloc,
      act: (bloc) => bloc.add(const OnboardingEvent.nextStepRequested()),
      expect: () => <OnboardingState>[
        const OnboardingState(
          organizationNameError: 'Informe o nome da organização.',
        ),
      ],
      verify: (_) {
        expect(progressRepository.saved.containsKey('user-1'), isFalse);
      },
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'advances to the segment step once the name is valid',
      build: buildBloc,
      seed: () => const OnboardingState(organizationName: 'Grupo Fashion XPTO'),
      act: (bloc) => bloc.add(const OnboardingEvent.nextStepRequested()),
      expect: () => <OnboardingState>[
        const OnboardingState(
          step: OnboardingStep.segment,
          organizationName: 'Grupo Fashion XPTO',
        ),
      ],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'blocks advancing past the segment step without a selection',
      build: buildBloc,
      seed: () => const OnboardingState(
        step: OnboardingStep.segment,
        organizationName: 'Grupo Fashion XPTO',
      ),
      act: (bloc) => bloc.add(const OnboardingEvent.nextStepRequested()),
      expect: () => <OnboardingState>[
        const OnboardingState(
          step: OnboardingStep.segment,
          organizationName: 'Grupo Fashion XPTO',
          segmentError: 'Selecione o segmento da organização.',
        ),
      ],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'moves back a step without losing any already-typed data',
      build: buildBloc,
      seed: () => const OnboardingState(
        step: OnboardingStep.segment,
        organizationName: 'Grupo Fashion XPTO',
      ),
      act: (bloc) => bloc.add(const OnboardingEvent.previousStepRequested()),
      expect: () => <OnboardingState>[
        const OnboardingState(organizationName: 'Grupo Fashion XPTO'),
      ],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'does nothing when previousStepRequested fires on the first step',
      build: buildBloc,
      act: (bloc) => bloc.add(const OnboardingEvent.previousStepRequested()),
      expect: () => <OnboardingState>[],
    );
  });

  group('OnboardingBloc — submitted', () {
    blocTest<OnboardingBloc, OnboardingState>(
      'blocks completion without the required name/segment, without '
      'calling CompleteOnboardingUseCase',
      build: buildBloc,
      seed: () => const OnboardingState(step: OnboardingStep.preferences),
      act: (bloc) => bloc.add(const OnboardingEvent.submitted()),
      expect: () => <OnboardingState>[
        const OnboardingState(
          step: OnboardingStep.preferences,
          organizationNameError: 'Informe o nome da organização.',
          segmentError: 'Selecione o segmento da organização.',
        ),
      ],
      verify: (_) {
        expect(organizationRepository.createCallCount, 0);
      },
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'creates the Organization, clears the saved progress and logs '
      'organization_created on success',
      build: buildBloc,
      setUp: () {
        organizationRepository.result = AppSuccess<Organization>(
          createdOrganization,
        );
        progressRepository.saved['user-1'] = const OnboardingProgress(
          organizationName: 'Grupo Fashion XPTO',
          segment: OrganizationSegment.apparel,
        );
      },
      seed: () => const OnboardingState(
        step: OnboardingStep.preferences,
        organizationName: 'Grupo Fashion XPTO',
        segment: OrganizationSegment.apparel,
      ),
      act: (bloc) => bloc.add(const OnboardingEvent.submitted()),
      expect: () => <OnboardingState>[
        const OnboardingState(
          step: OnboardingStep.preferences,
          organizationName: 'Grupo Fashion XPTO',
          segment: OrganizationSegment.apparel,
          submissionStatus: OnboardingSubmissionStatus.submitting,
        ),
        OnboardingState(
          step: OnboardingStep.preferences,
          organizationName: 'Grupo Fashion XPTO',
          segment: OrganizationSegment.apparel,
          submissionStatus: OnboardingSubmissionStatus.success,
          createdOrganization: createdOrganization,
        ),
      ],
      verify: (_) {
        expect(organizationRepository.createCallCount, 1);
        expect(progressRepository.saved.containsKey('user-1'), isFalse);
        expect(analyticsService.loggedEvents, hasLength(1));
        final event = analyticsService.loggedEvents.single;
        expect(event.name, AnalyticsEvents.organizationCreated);
        expect(event.parameters, containsPair('segment', 'apparel'));
        expect(event.parameters!.values, isNot(contains('Grupo Fashion XPTO')));
      },
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'surfaces a repository failure without clearing typed fields',
      build: buildBloc,
      setUp: () {
        organizationRepository.result = const AppFailure<Organization>(
          ConnectivityFailure('Sem conexão com a internet.'),
        );
      },
      seed: () => const OnboardingState(
        step: OnboardingStep.preferences,
        organizationName: 'Grupo Fashion XPTO',
        segment: OrganizationSegment.apparel,
      ),
      act: (bloc) => bloc.add(const OnboardingEvent.submitted()),
      expect: () => <OnboardingState>[
        const OnboardingState(
          step: OnboardingStep.preferences,
          organizationName: 'Grupo Fashion XPTO',
          segment: OrganizationSegment.apparel,
          submissionStatus: OnboardingSubmissionStatus.submitting,
        ),
        const OnboardingState(
          step: OnboardingStep.preferences,
          organizationName: 'Grupo Fashion XPTO',
          segment: OrganizationSegment.apparel,
          submissionStatus: OnboardingSubmissionStatus.failure,
          failure: ConnectivityFailure('Sem conexão com a internet.'),
        ),
      ],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'fails without calling the use case when there is no signed-in user',
      build: buildBloc,
      setUp: () => authRepository.user = null,
      seed: () => const OnboardingState(
        step: OnboardingStep.preferences,
        organizationName: 'Grupo Fashion XPTO',
        segment: OrganizationSegment.apparel,
      ),
      act: (bloc) => bloc.add(const OnboardingEvent.submitted()),
      expect: () => <OnboardingState>[
        const OnboardingState(
          step: OnboardingStep.preferences,
          organizationName: 'Grupo Fashion XPTO',
          segment: OrganizationSegment.apparel,
          submissionStatus: OnboardingSubmissionStatus.failure,
          failure: AuthenticationFailure(
            'É necessário estar autenticado para concluir a configuração.',
            code: 'onboarding_not_authenticated',
          ),
        ),
      ],
      verify: (_) {
        expect(organizationRepository.createCallCount, 0);
      },
    );
  });
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

final class _AuthRepositoryStub implements AuthRepository {
  _AuthRepositoryStub(this.user);

  SessionUser? user;

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
}

/// In-memory [OnboardingProgressRepository] test double — [saved] is
/// directly inspectable/pre-seedable by tests instead of needing `when`/
/// `verify` boilerplate, same rationale as `_UserProfileRepositoryStub` in
/// `sign_up_bloc_test.dart`.
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
  _OrganizationRepositoryStub(this.result);

  AppResult<Organization> result;
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
