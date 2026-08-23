import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/auth/auth.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/invites/invites.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockInviteRepository extends Mock implements InviteRepository {}

void main() {
  const signedInUser = SessionUser(uid: 'admin-1', emailVerified: true);

  final adminMembership = Membership(
    id: 'admin-1',
    organizationId: 'org-1',
    userId: 'admin-1',
    roleId: 'ADMIN',
    roleName: 'ADMIN',
    status: MembershipStatus.active,
    version: 1,
    createdAt: DateTime.utc(2026, 1, 1),
    createdBy: 'admin-1',
    updatedAt: DateTime.utc(2026, 1, 1),
    updatedBy: 'admin-1',
  );

  final issuedInvite = IssuedInvite(
    invite: Invite(
      id: 'invite-1',
      organizationId: 'org-1',
      email: 'novo@vestipro.com.br',
      roleName: SystemRoleName.salesRep,
      status: InviteStatus.pending,
      invitedByUserId: 'admin-1',
      invitedByName: 'Admin',
      expiresAt: DateTime.utc(2026, 1, 8),
      createdAt: DateTime.utc(2026, 1, 1),
      createdBy: 'admin-1',
      updatedAt: DateTime.utc(2026, 1, 1),
      updatedBy: 'admin-1',
    ),
    token: 'raw-token',
  );

  late _MockAuthRepository authRepository;
  late _MockMembershipRepository membershipRepository;
  late _MockInviteRepository inviteRepository;
  late FakeAnalyticsService analyticsService;

  InviteFormBloc buildBloc() {
    return InviteFormBloc(
      createInvite: CreateInviteUseCase(inviteRepository),
      membershipRepository: membershipRepository,
      authRepository: authRepository,
      analyticsService: analyticsService,
    );
  }

  setUpAll(() {
    registerFallbackValue(SystemRoleName.owner);
  });

  setUp(() {
    authRepository = _MockAuthRepository();
    membershipRepository = _MockMembershipRepository();
    inviteRepository = _MockInviteRepository();
    analyticsService = FakeAnalyticsService();

    when(() => authRepository.currentUser).thenReturn(signedInUser);
    when(
      () => membershipRepository.getByUser(
        organizationId: any(named: 'organizationId'),
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((_) async => AppSuccess<Membership>(adminMembership));
  });

  group('InviteFormBloc — started', () {
    blocTest<InviteFormBloc, InviteFormState>(
      "resolves the caller's assignable roles from their real Membership "
      '(ADMIN: every role except OWNER)',
      build: buildBloc,
      act: (bloc) => bloc.add(const InviteFormEvent.started('org-1')),
      expect: () => <InviteFormState>[
        InviteFormState(
          loadStatus: InviteFormLoadStatus.ready,
          organizationId: 'org-1',
          assignableRoles: SystemRoleName.values
              .where((role) => role != SystemRoleName.owner)
              .toList(),
        ),
      ],
    );

    blocTest<InviteFormBloc, InviteFormState>(
      'fails closed (no assignable roles) when the Membership cannot be '
      'resolved',
      build: buildBloc,
      setUp: () {
        when(
          () => membershipRepository.getByUser(
            organizationId: any(named: 'organizationId'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer(
          (_) async =>
              AppFailure<Membership>(const NotFoundFailure('No membership.')),
        );
      },
      act: (bloc) => bloc.add(const InviteFormEvent.started('org-1')),
      expect: () => <InviteFormState>[
        const InviteFormState(
          loadStatus: InviteFormLoadStatus.ready,
          organizationId: 'org-1',
        ),
      ],
    );
  });

  group('InviteFormBloc — field edits', () {
    blocTest<InviteFormBloc, InviteFormState>(
      'updates email and clears its error',
      build: buildBloc,
      seed: () => const InviteFormState(emailError: 'Informe um e-mail.'),
      act: (bloc) =>
          bloc.add(const InviteFormEvent.emailChanged('novo@vestipro.com.br')),
      expect: () => <InviteFormState>[
        const InviteFormState(email: 'novo@vestipro.com.br'),
      ],
    );

    blocTest<InviteFormBloc, InviteFormState>(
      'updates role and clears its error',
      build: buildBloc,
      seed: () => const InviteFormState(roleError: 'Selecione uma função.'),
      act: (bloc) =>
          bloc.add(const InviteFormEvent.roleSelected(SystemRoleName.salesRep)),
      expect: () => <InviteFormState>[
        const InviteFormState(role: SystemRoleName.salesRep),
      ],
    );
  });

  group('InviteFormBloc — submitted', () {
    blocTest<InviteFormBloc, InviteFormState>(
      'blocks submission and reports field errors when email/role are '
      'missing, without calling the repository',
      build: buildBloc,
      act: (bloc) => bloc.add(const InviteFormEvent.submitted()),
      expect: () => <InviteFormState>[
        const InviteFormState(
          emailError: 'Informe o e-mail do convidado.',
          roleError: 'Selecione uma função.',
        ),
      ],
      verify: (_) {
        verifyNever(
          () => inviteRepository.create(
            organizationId: any(named: 'organizationId'),
            email: any(named: 'email'),
            roleName: any(named: 'roleName'),
            message: any(named: 'message'),
          ),
        );
      },
    );

    blocTest<InviteFormBloc, InviteFormState>(
      'issues the invite, logs invite_sent (role only, never the e-mail) '
      'and exposes the one-time token on success',
      build: buildBloc,
      seed: () => const InviteFormState(
        organizationId: 'org-1',
        email: 'novo@vestipro.com.br',
        role: SystemRoleName.salesRep,
      ),
      setUp: () {
        when(
          () => inviteRepository.create(
            organizationId: any(named: 'organizationId'),
            email: any(named: 'email'),
            roleName: any(named: 'roleName'),
            message: any(named: 'message'),
          ),
        ).thenAnswer((_) async => AppSuccess<IssuedInvite>(issuedInvite));
      },
      act: (bloc) => bloc.add(const InviteFormEvent.submitted()),
      expect: () => <InviteFormState>[
        InviteFormState(
          organizationId: 'org-1',
          email: 'novo@vestipro.com.br',
          role: SystemRoleName.salesRep,
          submissionStatus: InviteFormSubmissionStatus.submitting,
        ),
        InviteFormState(
          organizationId: 'org-1',
          email: 'novo@vestipro.com.br',
          role: SystemRoleName.salesRep,
          submissionStatus: InviteFormSubmissionStatus.success,
          issuedInvite: issuedInvite,
        ),
      ],
      verify: (_) {
        expect(analyticsService.loggedEvents, hasLength(1));
        expect(
          analyticsService.loggedEvents.single.name,
          AnalyticsEvents.inviteSent,
        );
        expect(
          analyticsService.loggedEvents.single.parameters?['role'],
          'SALES_REP',
        );
      },
    );

    blocTest<InviteFormBloc, InviteFormState>(
      'reports the repository failure (e.g. ADMIN trying to invite an '
      'OWNER, rejected server-side) without logging analytics',
      build: buildBloc,
      seed: () => const InviteFormState(
        organizationId: 'org-1',
        email: 'novo@vestipro.com.br',
        role: SystemRoleName.owner,
      ),
      setUp: () {
        when(
          () => inviteRepository.create(
            organizationId: any(named: 'organizationId'),
            email: any(named: 'email'),
            roleName: any(named: 'roleName'),
            message: any(named: 'message'),
          ),
        ).thenAnswer(
          (_) async =>
              AppFailure<IssuedInvite>(const PermissionFailure('Not allowed.')),
        );
      },
      act: (bloc) => bloc.add(const InviteFormEvent.submitted()),
      expect: () => <InviteFormState>[
        InviteFormState(
          organizationId: 'org-1',
          email: 'novo@vestipro.com.br',
          role: SystemRoleName.owner,
          submissionStatus: InviteFormSubmissionStatus.submitting,
        ),
        InviteFormState(
          organizationId: 'org-1',
          email: 'novo@vestipro.com.br',
          role: SystemRoleName.owner,
          submissionStatus: InviteFormSubmissionStatus.failure,
          failure: const PermissionFailure('Not allowed.'),
        ),
      ],
      verify: (_) {
        expect(analyticsService.loggedEvents, isEmpty);
      },
    );
  });
}
