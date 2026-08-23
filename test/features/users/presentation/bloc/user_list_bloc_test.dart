import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/users/users.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockTeamRepository extends Mock implements TeamRepository {}

void main() {
  late _MockMembershipRepository membershipRepository;
  late _MockTeamRepository teamRepository;

  final owner = OrganizationUser(
    userId: 'owner-1',
    name: 'Ana Souza',
    email: 'ana@vestipro.com.br',
    roleName: 'OWNER',
    status: MembershipStatus.active,
  );
  final rep = OrganizationUser(
    userId: 'rep-1',
    name: 'Bruno Lima',
    email: 'bruno@vestipro.com.br',
    roleName: 'SALES_REP',
    status: MembershipStatus.inactive,
  );

  UserListBloc buildBloc() {
    return UserListBloc(
      listOrganizationUsers: ListOrganizationUsersUseCase(
        membershipRepository,
        teamRepository,
      ),
    );
  }

  Membership toMembership(OrganizationUser user) {
    return Membership(
      id: user.userId,
      organizationId: 'org-1',
      userId: user.userId,
      roleId: user.roleName,
      roleName: user.roleName,
      status: user.status,
      version: 1,
      createdAt: DateTime.utc(2026, 1, 1),
      createdBy: 'owner-1',
      updatedAt: DateTime.utc(2026, 1, 1),
      updatedBy: 'owner-1',
      name: user.name,
      email: user.email,
    );
  }

  setUp(() {
    membershipRepository = _MockMembershipRepository();
    teamRepository = _MockTeamRepository();
    when(
      () => teamRepository.listByOrganization('org-1'),
    ).thenAnswer((_) async => const AppSuccess<List<Team>>([]));
  });

  group('UserListBloc — started', () {
    blocTest<UserListBloc, UserListState>(
      'loads and exposes every user of the organization',
      build: buildBloc,
      setUp: () {
        when(() => membershipRepository.listByOrganization('org-1')).thenAnswer(
          (_) async => AppSuccess<List<Membership>>(
            [owner, rep].map(toMembership).toList(),
          ),
        );
      },
      act: (bloc) => bloc.add(const UserListEvent.started('org-1')),
      expect: () => <UserListState>[
        const UserListState(
          loadStatus: UserListLoadStatus.loading,
          organizationId: 'org-1',
        ),
        UserListState(
          loadStatus: UserListLoadStatus.ready,
          organizationId: 'org-1',
          allUsers: [owner, rep],
        ),
      ],
      verify: (bloc) {
        expect(bloc.state.visibleUsers, [owner, rep]);
        expect(bloc.state.hasMore, isFalse);
      },
    );

    blocTest<UserListBloc, UserListState>(
      'reports a load failure without swallowing it into an empty list',
      build: buildBloc,
      setUp: () {
        when(() => membershipRepository.listByOrganization('org-1')).thenAnswer(
          (_) async => AppFailure<List<Membership>>(
            const ConnectivityFailure('Offline.'),
          ),
        );
      },
      act: (bloc) => bloc.add(const UserListEvent.started('org-1')),
      expect: () => <UserListState>[
        const UserListState(
          loadStatus: UserListLoadStatus.loading,
          organizationId: 'org-1',
        ),
        const UserListState(
          loadStatus: UserListLoadStatus.failure,
          organizationId: 'org-1',
          loadFailure: ConnectivityFailure('Offline.'),
        ),
      ],
    );
  });

  group('UserListBloc — searchChanged', () {
    blocTest<UserListBloc, UserListState>(
      'narrows the roster by name/e-mail, case-insensitively, and resets '
      'pagination',
      build: buildBloc,
      seed: () => UserListState(
        loadStatus: UserListLoadStatus.ready,
        organizationId: 'org-1',
        allUsers: [owner, rep],
        visibleCount: 1,
      ),
      act: (bloc) => bloc.add(const UserListEvent.searchChanged('BRUNO')),
      expect: () => <UserListState>[
        UserListState(
          loadStatus: UserListLoadStatus.ready,
          organizationId: 'org-1',
          allUsers: [owner, rep],
          searchQuery: 'BRUNO',
        ),
      ],
      verify: (bloc) {
        expect(bloc.state.filteredUsers, [rep]);
      },
    );

    blocTest<UserListBloc, UserListState>(
      'yields an empty filtered list for a query that matches nobody',
      build: buildBloc,
      seed: () => UserListState(
        loadStatus: UserListLoadStatus.ready,
        organizationId: 'org-1',
        allUsers: [owner, rep],
      ),
      act: (bloc) => bloc.add(const UserListEvent.searchChanged('nao-existe')),
      verify: (bloc) {
        expect(bloc.state.filteredUsers, isEmpty);
        expect(bloc.state.visibleUsers, isEmpty);
      },
    );
  });

  group('UserListBloc — filters', () {
    blocTest<UserListBloc, UserListState>(
      'combines role and status filters',
      build: buildBloc,
      seed: () => UserListState(
        loadStatus: UserListLoadStatus.ready,
        organizationId: 'org-1',
        allUsers: [owner, rep],
      ),
      act: (bloc) => bloc
        ..add(const UserListEvent.roleFilterChanged('SALES_REP'))
        ..add(
          const UserListEvent.statusFilterChanged(MembershipStatus.inactive),
        ),
      verify: (bloc) {
        expect(bloc.state.filteredUsers, [rep]);
      },
    );

    blocTest<UserListBloc, UserListState>(
      'a role filter combined with a status nobody matches yields an '
      'empty result, not a crash',
      build: buildBloc,
      seed: () => UserListState(
        loadStatus: UserListLoadStatus.ready,
        organizationId: 'org-1',
        allUsers: [owner, rep],
      ),
      act: (bloc) => bloc
        ..add(const UserListEvent.roleFilterChanged('SALES_REP'))
        ..add(const UserListEvent.statusFilterChanged(MembershipStatus.active)),
      verify: (bloc) {
        expect(bloc.state.filteredUsers, isEmpty);
      },
    );

    blocTest<UserListBloc, UserListState>(
      'clearing a filter (null) restores the previously narrowed users',
      build: buildBloc,
      seed: () => UserListState(
        loadStatus: UserListLoadStatus.ready,
        organizationId: 'org-1',
        allUsers: [owner, rep],
        roleFilter: 'SALES_REP',
      ),
      act: (bloc) => bloc.add(const UserListEvent.roleFilterChanged(null)),
      verify: (bloc) {
        expect(bloc.state.filteredUsers, [owner, rep]);
      },
    );
  });

  group('UserListBloc — loadMoreRequested', () {
    blocTest<UserListBloc, UserListState>(
      'reveals one more page without re-fetching from the repository',
      build: buildBloc,
      seed: () => UserListState(
        loadStatus: UserListLoadStatus.ready,
        organizationId: 'org-1',
        allUsers: [owner, rep],
        visibleCount: 1,
      ),
      act: (bloc) => bloc.add(const UserListEvent.loadMoreRequested()),
      verify: (bloc) {
        expect(bloc.state.visibleUsers, [owner, rep]);
        expect(bloc.state.hasMore, isFalse);
        verifyNever(() => membershipRepository.listByOrganization(any()));
      },
    );

    blocTest<UserListBloc, UserListState>(
      'is a no-op once every filtered user is already visible',
      build: buildBloc,
      seed: () => UserListState(
        loadStatus: UserListLoadStatus.ready,
        organizationId: 'org-1',
        allUsers: [owner],
      ),
      act: (bloc) => bloc.add(const UserListEvent.loadMoreRequested()),
      expect: () => <UserListState>[],
    );
  });
}
