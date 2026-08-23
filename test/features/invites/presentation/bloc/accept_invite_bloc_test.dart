import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/auth/auth.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/invites/invites.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockInviteAcceptanceRepository extends Mock
    implements InviteAcceptanceRepository {}

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  const validPreview = InvitePreview(
    outcome: InviteAcceptanceOutcome.valid,
    organizationId: 'org-1',
    organizationName: 'Grupo Fashion XPTO',
    email: 'convidado@vestipro.com.br',
    roleName: SystemRoleName.salesRep,
  );

  const acceptedInvite = AcceptedInvite(
    organizationId: 'org-1',
    organizationName: 'Grupo Fashion XPTO',
    roleName: SystemRoleName.salesRep,
  );

  late _MockInviteAcceptanceRepository repository;
  late _MockAuthRepository authRepository;
  late FakeAnalyticsService analyticsService;

  AcceptInviteBloc buildBloc() {
    return AcceptInviteBloc(
      validateInvite: ValidateInviteUseCase(repository),
      acceptInvite: AcceptInviteUseCase(repository),
      authRepository: authRepository,
      analyticsService: analyticsService,
    );
  }

  setUp(() {
    repository = _MockInviteAcceptanceRepository();
    authRepository = _MockAuthRepository();
    analyticsService = FakeAnalyticsService();
  });

  group('AcceptInviteBloc — started', () {
    blocTest<AcceptInviteBloc, AcceptInviteState>(
      'reports a valid outcome with no active session',
      setUp: () {
        when(
          () => repository.validate(token: any(named: 'token')),
        ).thenAnswer((_) async => const AppSuccess(validPreview));
        when(() => authRepository.currentUser).thenReturn(null);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const AcceptInviteEvent.started('token-1')),
      skip: 1,
      expect: () => [
        isA<AcceptInviteState>()
            .having(
              (s) => s.validationStatus,
              'validationStatus',
              AcceptInviteValidationStatus.ready,
            )
            .having((s) => s.outcome, 'outcome', InviteAcceptanceOutcome.valid)
            .having((s) => s.hasActiveSession, 'hasActiveSession', false)
            .having(
              (s) => s.organizationName,
              'organizationName',
              'Grupo Fashion XPTO',
            ),
      ],
    );

    blocTest<AcceptInviteBloc, AcceptInviteState>(
      'reports no mismatch when the active session e-mail matches the '
      'invite (case-insensitively)',
      setUp: () {
        when(
          () => repository.validate(token: any(named: 'token')),
        ).thenAnswer((_) async => const AppSuccess(validPreview));
        when(() => authRepository.currentUser).thenReturn(
          const SessionUser(
            uid: 'user-1',
            email: 'Convidado@Vestipro.com.br',
            emailVerified: true,
          ),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const AcceptInviteEvent.started('token-1')),
      skip: 1,
      expect: () => [
        isA<AcceptInviteState>()
            .having((s) => s.hasActiveSession, 'hasActiveSession', true)
            .having(
              (s) => s.sessionEmailMismatch,
              'sessionEmailMismatch',
              false,
            ),
      ],
    );

    blocTest<AcceptInviteBloc, AcceptInviteState>(
      'reports a mismatch when the active session e-mail diverges from '
      'the invite',
      setUp: () {
        when(
          () => repository.validate(token: any(named: 'token')),
        ).thenAnswer((_) async => const AppSuccess(validPreview));
        when(() => authRepository.currentUser).thenReturn(
          const SessionUser(
            uid: 'user-1',
            email: 'outro@vestipro.com.br',
            emailVerified: true,
          ),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const AcceptInviteEvent.started('token-1')),
      skip: 1,
      expect: () => [
        isA<AcceptInviteState>()
            .having((s) => s.hasActiveSession, 'hasActiveSession', true)
            .having(
              (s) => s.sessionEmailMismatch,
              'sessionEmailMismatch',
              true,
            ),
      ],
    );

    blocTest<AcceptInviteBloc, AcceptInviteState>(
      'reports each non-valid outcome as ready, never as error',
      setUp: () {
        when(() => repository.validate(token: any(named: 'token'))).thenAnswer(
          (_) async => const AppSuccess(
            InvitePreview(outcome: InviteAcceptanceOutcome.expired),
          ),
        );
        when(() => authRepository.currentUser).thenReturn(null);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const AcceptInviteEvent.started('token-1')),
      skip: 1,
      expect: () => [
        isA<AcceptInviteState>()
            .having(
              (s) => s.validationStatus,
              'validationStatus',
              AcceptInviteValidationStatus.ready,
            )
            .having(
              (s) => s.outcome,
              'outcome',
              InviteAcceptanceOutcome.expired,
            ),
      ],
    );

    blocTest<AcceptInviteBloc, AcceptInviteState>(
      'reports a technical failure as error, distinct from an invalid '
      'business outcome',
      setUp: () {
        when(() => repository.validate(token: any(named: 'token'))).thenAnswer(
          (_) async => const AppFailure(ConnectivityFailure('Offline.')),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const AcceptInviteEvent.started('token-1')),
      skip: 1,
      expect: () => [
        isA<AcceptInviteState>().having(
          (s) => s.validationStatus,
          'validationStatus',
          AcceptInviteValidationStatus.error,
        ),
      ],
    );
  });

  group('AcceptInviteBloc — confirmed', () {
    blocTest<AcceptInviteBloc, AcceptInviteState>(
      'accepts the invite, logs invite_accepted (role only) and exposes '
      'the joined organization',
      setUp: () {
        when(
          () => repository.accept(token: any(named: 'token')),
        ).thenAnswer((_) async => const AppSuccess(acceptedInvite));
      },
      build: buildBloc,
      seed: () => const AcceptInviteState(token: 'token-1'),
      act: (bloc) => bloc.add(const AcceptInviteEvent.confirmed()),
      expect: () => [
        isA<AcceptInviteState>().having(
          (s) => s.acceptanceStatus,
          'acceptanceStatus',
          AcceptInviteAcceptanceStatus.submitting,
        ),
        isA<AcceptInviteState>()
            .having(
              (s) => s.acceptanceStatus,
              'acceptanceStatus',
              AcceptInviteAcceptanceStatus.success,
            )
            .having(
              (s) => s.acceptedOrganizationId,
              'acceptedOrganizationId',
              'org-1',
            ),
      ],
      verify: (_) {
        expect(analyticsService.loggedEvents, hasLength(1));
        final logged = analyticsService.loggedEvents.single;
        expect(logged.name, AnalyticsEvents.inviteAccepted);
        expect(logged.parameters, {'role': 'SALES_REP'});
      },
    );

    blocTest<AcceptInviteBloc, AcceptInviteState>(
      'reports a repository failure without logging analytics (e.g. a '
      'race where the invite was accepted elsewhere first)',
      setUp: () {
        when(() => repository.accept(token: any(named: 'token'))).thenAnswer(
          (_) async => const AppFailure(
            ConflictFailure('Este convite já foi utilizado.'),
          ),
        );
      },
      build: buildBloc,
      seed: () => const AcceptInviteState(token: 'token-1'),
      act: (bloc) => bloc.add(const AcceptInviteEvent.confirmed()),
      expect: () => [
        isA<AcceptInviteState>().having(
          (s) => s.acceptanceStatus,
          'acceptanceStatus',
          AcceptInviteAcceptanceStatus.submitting,
        ),
        isA<AcceptInviteState>().having(
          (s) => s.acceptanceStatus,
          'acceptanceStatus',
          AcceptInviteAcceptanceStatus.failure,
        ),
      ],
      verify: (_) {
        expect(analyticsService.loggedEvents, isEmpty);
      },
    );
  });

  group('AcceptInviteBloc — signOutRequested', () {
    blocTest<AcceptInviteBloc, AcceptInviteState>(
      'signs out and clears the active-session flags',
      setUp: () {
        when(
          () => authRepository.signOut(),
        ).thenAnswer((_) async => const AppSuccess<void>(null));
      },
      build: buildBloc,
      seed: () => const AcceptInviteState(
        hasActiveSession: true,
        sessionEmailMismatch: true,
      ),
      act: (bloc) => bloc.add(const AcceptInviteEvent.signOutRequested()),
      expect: () => [
        isA<AcceptInviteState>()
            .having((s) => s.hasActiveSession, 'hasActiveSession', false)
            .having(
              (s) => s.sessionEmailMismatch,
              'sessionEmailMismatch',
              false,
            ),
      ],
      verify: (_) {
        verify(() => authRepository.signOut()).called(1);
      },
    );
  });
}
