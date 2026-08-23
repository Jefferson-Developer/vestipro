import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/auth/auth.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/users/users.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockUserRoleRepository extends Mock implements UserRoleRepository {}

void main() {
  group('UserRoleEditBloc', () {
    const signedInUser = SessionUser(uid: 'admin-1', emailVerified: true);

    final repUser = OrganizationUser(
      userId: 'rep-1',
      name: 'Bruno Lima',
      email: 'bruno@vestipro.com.br',
      roleName: 'SALES_REP',
      status: MembershipStatus.active,
    );
    final ownerUser = OrganizationUser(
      userId: 'owner-1',
      name: 'Ana Souza',
      email: 'ana@vestipro.com.br',
      roleName: 'OWNER',
      status: MembershipStatus.active,
    );
    final update = UserRoleUpdateResult(
      organizationId: 'org-1',
      targetUserId: 'rep-1',
      previousRoleName: SystemRoleName.salesRep,
      roleName: SystemRoleName.admin,
      updatedAt: DateTime.utc(2026, 1, 1),
    );

    late _MockAuthRepository authRepository;
    late _MockMembershipRepository membershipRepository;
    late _MockUserRoleRepository userRoleRepository;
    late FakeAnalyticsService analyticsService;

    Membership membership({
      required String userId,
      required String roleName,
      MembershipStatus status = MembershipStatus.active,
    }) {
      return Membership(
        id: userId,
        organizationId: 'org-1',
        userId: userId,
        roleId: roleName,
        roleName: roleName,
        status: status,
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'owner-1',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'owner-1',
      );
    }

    UserRoleEditBloc buildBloc() {
      return UserRoleEditBloc(
        updateUserRole: UpdateUserRoleUseCase(userRoleRepository),
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
      userRoleRepository = _MockUserRoleRepository();
      analyticsService = FakeAnalyticsService();
      when(() => authRepository.currentUser).thenReturn(signedInUser);
    });

    blocTest<UserRoleEditBloc, UserRoleEditState>(
      'resolves ADMIN assignable roles without OWNER for a lower target',
      build: buildBloc,
      setUp: () {
        when(
          () => membershipRepository.getByUser(
            organizationId: 'org-1',
            userId: 'admin-1',
          ),
        ).thenAnswer(
          (_) async => AppSuccess<Membership>(
            membership(userId: 'admin-1', roleName: 'ADMIN'),
          ),
        );
      },
      act: (bloc) => bloc.add(
        UserRoleEditEvent.started(organizationId: 'org-1', user: repUser),
      ),
      expect: () => <UserRoleEditState>[
        UserRoleEditState(
          loadStatus: UserRoleEditLoadStatus.ready,
          organizationId: 'org-1',
          user: repUser,
          currentRole: SystemRoleName.salesRep,
          selectedRole: SystemRoleName.salesRep,
          assignableRoles: SystemRoleName.values
              .where((role) => role != SystemRoleName.owner)
              .toList(),
        ),
      ],
    );

    blocTest<UserRoleEditBloc, UserRoleEditState>(
      'fails closed when an ADMIN tries to edit an OWNER target',
      build: buildBloc,
      setUp: () {
        when(
          () => membershipRepository.getByUser(
            organizationId: 'org-1',
            userId: 'admin-1',
          ),
        ).thenAnswer(
          (_) async => AppSuccess<Membership>(
            membership(userId: 'admin-1', roleName: 'ADMIN'),
          ),
        );
      },
      act: (bloc) => bloc.add(
        UserRoleEditEvent.started(organizationId: 'org-1', user: ownerUser),
      ),
      expect: () => <UserRoleEditState>[
        UserRoleEditState(
          loadStatus: UserRoleEditLoadStatus.ready,
          organizationId: 'org-1',
          user: ownerUser,
          currentRole: SystemRoleName.owner,
        ),
      ],
    );

    blocTest<UserRoleEditBloc, UserRoleEditState>(
      'updates the role, logs analytics without PII and exposes success',
      build: buildBloc,
      seed: () => UserRoleEditState(
        loadStatus: UserRoleEditLoadStatus.ready,
        organizationId: 'org-1',
        user: repUser,
        currentRole: SystemRoleName.salesRep,
        selectedRole: SystemRoleName.admin,
        assignableRoles: const <SystemRoleName>[
          SystemRoleName.admin,
          SystemRoleName.salesManager,
          SystemRoleName.salesRep,
        ],
      ),
      setUp: () {
        when(
          () => userRoleRepository.updateUserRole(
            organizationId: any(named: 'organizationId'),
            targetUserId: any(named: 'targetUserId'),
            roleName: any(named: 'roleName'),
          ),
        ).thenAnswer((_) async => AppSuccess<UserRoleUpdateResult>(update));
      },
      act: (bloc) => bloc.add(const UserRoleEditEvent.submitted()),
      expect: () => <UserRoleEditState>[
        UserRoleEditState(
          loadStatus: UserRoleEditLoadStatus.ready,
          organizationId: 'org-1',
          user: repUser,
          currentRole: SystemRoleName.salesRep,
          selectedRole: SystemRoleName.admin,
          assignableRoles: const <SystemRoleName>[
            SystemRoleName.admin,
            SystemRoleName.salesManager,
            SystemRoleName.salesRep,
          ],
          submissionStatus: UserRoleEditSubmissionStatus.submitting,
        ),
        UserRoleEditState(
          loadStatus: UserRoleEditLoadStatus.ready,
          organizationId: 'org-1',
          user: repUser,
          currentRole: SystemRoleName.admin,
          selectedRole: SystemRoleName.admin,
          assignableRoles: const <SystemRoleName>[
            SystemRoleName.admin,
            SystemRoleName.salesManager,
            SystemRoleName.salesRep,
          ],
          submissionStatus: UserRoleEditSubmissionStatus.success,
          result: update,
        ),
      ],
      verify: (_) {
        verify(
          () => userRoleRepository.updateUserRole(
            organizationId: 'org-1',
            targetUserId: 'rep-1',
            roleName: SystemRoleName.admin,
          ),
        ).called(1);
        expect(analyticsService.loggedEvents.single.name, 'user_role_updated');
        expect(
          analyticsService.loggedEvents.single.parameters,
          <String, Object?>{'previous_role': 'SALES_REP', 'new_role': 'ADMIN'},
        );
      },
    );

    blocTest<UserRoleEditBloc, UserRoleEditState>(
      'reports the last active OWNER failure from the repository',
      build: buildBloc,
      seed: () => UserRoleEditState(
        loadStatus: UserRoleEditLoadStatus.ready,
        organizationId: 'org-1',
        user: ownerUser,
        currentRole: SystemRoleName.owner,
        selectedRole: SystemRoleName.admin,
        assignableRoles: SystemRoleName.values,
      ),
      setUp: () {
        when(
          () => userRoleRepository.updateUserRole(
            organizationId: any(named: 'organizationId'),
            targetUserId: any(named: 'targetUserId'),
            roleName: any(named: 'roleName'),
          ),
        ).thenAnswer(
          (_) async => AppFailure<UserRoleUpdateResult>(
            const ConflictFailure(
              'Não é possível alterar este perfil porque ele é o último OWNER ativo da organização.',
            ),
          ),
        );
      },
      act: (bloc) => bloc.add(const UserRoleEditEvent.submitted()),
      expect: () => <UserRoleEditState>[
        UserRoleEditState(
          loadStatus: UserRoleEditLoadStatus.ready,
          organizationId: 'org-1',
          user: ownerUser,
          currentRole: SystemRoleName.owner,
          selectedRole: SystemRoleName.admin,
          assignableRoles: SystemRoleName.values,
          submissionStatus: UserRoleEditSubmissionStatus.submitting,
        ),
        UserRoleEditState(
          loadStatus: UserRoleEditLoadStatus.ready,
          organizationId: 'org-1',
          user: ownerUser,
          currentRole: SystemRoleName.owner,
          selectedRole: SystemRoleName.admin,
          assignableRoles: SystemRoleName.values,
          submissionStatus: UserRoleEditSubmissionStatus.failure,
          failure: const ConflictFailure(
            'Não é possível alterar este perfil porque ele é o último OWNER ativo da organização.',
          ),
        ),
      ],
      verify: (_) {
        expect(analyticsService.loggedEvents, isEmpty);
      },
    );
  });
}
