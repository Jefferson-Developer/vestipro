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
  late ListOrganizationUsersUseCase useCase;

  Membership buildMembership({
    required String userId,
    String? name,
    String? email,
    String roleName = 'SALES_REP',
    MembershipStatus status = MembershipStatus.active,
    List<String> teamIds = const <String>[],
  }) {
    return Membership(
      id: userId,
      organizationId: 'org-1',
      userId: userId,
      roleId: roleName,
      roleName: roleName,
      teamIds: teamIds,
      status: status,
      version: 1,
      createdAt: DateTime.utc(2026, 1, 1),
      createdBy: 'owner-1',
      updatedAt: DateTime.utc(2026, 1, 1),
      updatedBy: 'owner-1',
      name: name,
      email: email,
    );
  }

  setUp(() {
    membershipRepository = _MockMembershipRepository();
    teamRepository = _MockTeamRepository();
    useCase = ListOrganizationUsersUseCase(
      membershipRepository,
      teamRepository,
    );

    when(
      () => teamRepository.listByOrganization('org-1'),
    ).thenAnswer((_) async => const AppSuccess<List<Team>>([]));
  });

  group('ListOrganizationUsersUseCase', () {
    test('joins each Membership with its denormalized name/email, sorted by '
        'name', () async {
      when(() => membershipRepository.listByOrganization('org-1')).thenAnswer(
        (_) async => AppSuccess<List<Membership>>([
          buildMembership(
            userId: 'user-2',
            name: 'Zeca',
            email: 'zeca@vestipro.com.br',
          ),
          buildMembership(
            userId: 'user-1',
            name: 'Ana',
            email: 'ana@vestipro.com.br',
          ),
        ]),
      );

      final result = await useCase('org-1');

      expect(result, isA<AppSuccess<List<OrganizationUser>>>());
      final users = (result as AppSuccess<List<OrganizationUser>>).value;
      expect(users.map((u) => u.userId), <String>['user-1', 'user-2']);
      expect(users.first.name, 'Ana');
      expect(users.first.email, 'ana@vestipro.com.br');
    });

    test('falls back to userId/empty e-mail for a Membership created before '
        'name/email were denormalized (TASK-042)', () async {
      when(() => membershipRepository.listByOrganization('org-1')).thenAnswer(
        (_) async => AppSuccess<List<Membership>>([
          buildMembership(userId: 'legacy-user'),
        ]),
      );

      final result = await useCase('org-1');

      final users = (result as AppSuccess<List<OrganizationUser>>).value;
      expect(users.single.name, 'legacy-user');
      expect(users.single.email, '');
    });

    test('resolves teamIds into teamNames from TeamRepository', () async {
      when(() => membershipRepository.listByOrganization('org-1')).thenAnswer(
        (_) async => AppSuccess<List<Membership>>([
          buildMembership(
            userId: 'user-1',
            name: 'Ana',
            teamIds: const <String>['team-1', 'team-unknown'],
          ),
        ]),
      );
      when(() => teamRepository.listByOrganization('org-1')).thenAnswer(
        (_) async => AppSuccess<List<Team>>([
          Team(
            id: 'team-1',
            organizationId: 'org-1',
            name: 'Time Sul',
            version: 1,
            createdAt: DateTime.utc(2026, 1, 1),
            createdBy: 'owner-1',
            updatedAt: DateTime.utc(2026, 1, 1),
            updatedBy: 'owner-1',
          ),
        ]),
      );

      final result = await useCase('org-1');

      final user = (result as AppSuccess<List<OrganizationUser>>).value.single;
      expect(user.teamIds, <String>['team-1', 'team-unknown']);
      expect(user.teamNames, <String>['Time Sul']);
    });

    test('still returns the roster (with empty teamNames) when TeamRepository '
        'fails — a Team lookup failure never blocks the user list', () async {
      when(() => membershipRepository.listByOrganization('org-1')).thenAnswer(
        (_) async => AppSuccess<List<Membership>>([
          buildMembership(
            userId: 'user-1',
            name: 'Ana',
            teamIds: const <String>['team-1'],
          ),
        ]),
      );
      when(() => teamRepository.listByOrganization('org-1')).thenAnswer(
        (_) async =>
            AppFailure<List<Team>>(const ConnectivityFailure('Offline.')),
      );

      final result = await useCase('org-1');

      expect(result, isA<AppSuccess<List<OrganizationUser>>>());
      final user = (result as AppSuccess<List<OrganizationUser>>).value.single;
      expect(user.teamNames, isEmpty);
    });

    test('propagates a Membership listing failure', () async {
      when(() => membershipRepository.listByOrganization('org-1')).thenAnswer(
        (_) async =>
            AppFailure<List<Membership>>(const ConnectivityFailure('Offline.')),
      );

      final result = await useCase('org-1');

      expect(
        result,
        isA<AppFailure<List<OrganizationUser>>>().having(
          (failure) => failure.failure,
          'failure',
          isA<ConnectivityFailure>(),
        ),
      );
    });

    test('returns an empty list for an organization with no members', () async {
      when(
        () => membershipRepository.listByOrganization('org-1'),
      ).thenAnswer((_) async => const AppSuccess<List<Membership>>([]));

      final result = await useCase('org-1');

      expect(
        result,
        isA<AppSuccess<List<OrganizationUser>>>().having(
          (success) => success.value,
          'value',
          isEmpty,
        ),
      );
    });
  });
}
