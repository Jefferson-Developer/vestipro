import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/dashboards/dashboards.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockTeamRepository extends Mock implements TeamRepository {}

void main() {
  late _MockMembershipRepository membershipRepository;
  late _MockTeamRepository teamRepository;
  late ExecutiveDashboardVisibilityService service;

  setUp(() {
    membershipRepository = _MockMembershipRepository();
    teamRepository = _MockTeamRepository();
    service = ExecutiveDashboardVisibilityService(
      membershipRepository,
      teamRepository,
    );
  });

  Membership membershipOf(String roleName, {List<String> teamIds = const []}) {
    return Membership(
      id: 'user-1',
      organizationId: 'org-1',
      userId: 'user-1',
      roleId: roleName,
      roleName: roleName,
      teamIds: teamIds,
      status: MembershipStatus.active,
      version: 1,
      createdAt: DateTime.utc(2026, 1, 1),
      createdBy: 'owner-1',
      updatedAt: DateTime.utc(2026, 1, 1),
      updatedBy: 'owner-1',
    );
  }

  void stubMembership(Membership membership) {
    when(
      () => membershipRepository.getByUser(
        organizationId: 'org-1',
        userId: 'user-1',
      ),
    ).thenAnswer((_) async => AppSuccess<Membership>(membership));
  }

  group('ExecutiveDashboardVisibilityService', () {
    test(
      'returns a validation failure for a blank organizationId/userId',
      () async {
        final result = await service.resolve(organizationId: '', userId: '');

        expect(result, isA<AppFailure<ExecutiveDashboardVisibilityFilter>>());
      },
    );

    for (final roleName in <String>['OWNER', 'ADMIN', 'FINANCE']) {
      test('$roleName resolves to allOrganization', () async {
        stubMembership(membershipOf(roleName));

        final result = await service.resolve(
          organizationId: 'org-1',
          userId: 'user-1',
        );

        final filter =
            (result as AppSuccess<ExecutiveDashboardVisibilityFilter>).value;
        expect(filter.mode, ExecutiveDashboardVisibilityMode.allOrganization);
        expect(filter.canViewCompany('any-company'), isTrue);
        expect(filter.canViewTeam('any-team'), isTrue);
      });
    }

    test('SALES_MANAGER resolves to ownScope, limited to managed teams and '
        'their companies', () async {
      stubMembership(membershipOf('SALES_MANAGER', teamIds: ['team-a']));
      when(() => teamRepository.listByOrganization('org-1')).thenAnswer(
        (_) async => AppSuccess<List<Team>>(<Team>[
          Team(
            id: 'team-a',
            organizationId: 'org-1',
            name: 'Equipe A',
            companyId: 'company-a',
            managerUserId: 'someone-else',
            version: 1,
            createdAt: DateTime.utc(2026, 1, 1),
            createdBy: 'owner-1',
            updatedAt: DateTime.utc(2026, 1, 1),
            updatedBy: 'owner-1',
          ),
          Team(
            id: 'team-b',
            organizationId: 'org-1',
            name: 'Equipe B',
            companyId: 'company-b',
            managerUserId: 'user-1',
            version: 1,
            createdAt: DateTime.utc(2026, 1, 1),
            createdBy: 'owner-1',
            updatedAt: DateTime.utc(2026, 1, 1),
            updatedBy: 'owner-1',
          ),
          Team(
            id: 'team-c',
            organizationId: 'org-1',
            name: 'Equipe C',
            companyId: 'company-c',
            managerUserId: 'stranger',
            version: 1,
            createdAt: DateTime.utc(2026, 1, 1),
            createdBy: 'owner-1',
            updatedAt: DateTime.utc(2026, 1, 1),
            updatedBy: 'owner-1',
          ),
        ]),
      );

      final result = await service.resolve(
        organizationId: 'org-1',
        userId: 'user-1',
      );

      final filter =
          (result as AppSuccess<ExecutiveDashboardVisibilityFilter>).value;
      expect(filter.mode, ExecutiveDashboardVisibilityMode.ownScope);
      // team-a: member of it (teamIds); team-b: manages it.
      expect(filter.canViewTeam('team-a'), isTrue);
      expect(filter.canViewTeam('team-b'), isTrue);
      expect(filter.canViewTeam('team-c'), isFalse);
      expect(filter.canViewCompany('company-a'), isTrue);
      expect(filter.canViewCompany('company-b'), isTrue);
      expect(filter.canViewCompany('company-c'), isFalse);
    });

    test('SALES_MANAGER with no managed team resolves to none', () async {
      stubMembership(membershipOf('SALES_MANAGER'));
      when(
        () => teamRepository.listByOrganization('org-1'),
      ).thenAnswer((_) async => const AppSuccess<List<Team>>(<Team>[]));

      final result = await service.resolve(
        organizationId: 'org-1',
        userId: 'user-1',
      );

      final filter =
          (result as AppSuccess<ExecutiveDashboardVisibilityFilter>).value;
      expect(filter.mode, ExecutiveDashboardVisibilityMode.none);
      expect(filter.canViewAny, isFalse);
    });

    for (final roleName in <String>[
      'SALES_REP',
      'SALES_ASSISTANT',
      'READ_ONLY',
    ]) {
      test('$roleName resolves to none', () async {
        stubMembership(membershipOf(roleName));

        final result = await service.resolve(
          organizationId: 'org-1',
          userId: 'user-1',
        );

        final filter =
            (result as AppSuccess<ExecutiveDashboardVisibilityFilter>).value;
        expect(filter.mode, ExecutiveDashboardVisibilityMode.none);
      });
    }

    test('an inactive Membership resolves to none', () async {
      stubMembership(
        membershipOf('OWNER').copyWith(status: MembershipStatus.inactive),
      );

      final result = await service.resolve(
        organizationId: 'org-1',
        userId: 'user-1',
      );

      final filter =
          (result as AppSuccess<ExecutiveDashboardVisibilityFilter>).value;
      expect(filter.mode, ExecutiveDashboardVisibilityMode.none);
    });

    test('no Membership at all resolves to none, never a failure', () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'user-1',
        ),
      ).thenAnswer(
        (_) async => const AppFailure<Membership>(
          NotFoundFailure('Not found.', code: 'membership_not_found'),
        ),
      );

      final result = await service.resolve(
        organizationId: 'org-1',
        userId: 'user-1',
      );

      final filter =
          (result as AppSuccess<ExecutiveDashboardVisibilityFilter>).value;
      expect(filter.mode, ExecutiveDashboardVisibilityMode.none);
    });

    test('a repository failure while resolving Membership propagates as a '
        'failure', () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'user-1',
        ),
      ).thenAnswer(
        (_) async =>
            const AppFailure<Membership>(ServerFailure('boom', code: 'boom')),
      );

      final result = await service.resolve(
        organizationId: 'org-1',
        userId: 'user-1',
      );

      expect(result, isA<AppFailure<ExecutiveDashboardVisibilityFilter>>());
    });

    test('a repository failure while resolving Teams propagates as a '
        'failure', () async {
      stubMembership(membershipOf('SALES_MANAGER', teamIds: ['team-a']));
      when(() => teamRepository.listByOrganization('org-1')).thenAnswer(
        (_) async =>
            const AppFailure<List<Team>>(ServerFailure('boom', code: 'boom')),
      );

      final result = await service.resolve(
        organizationId: 'org-1',
        userId: 'user-1',
      );

      expect(result, isA<AppFailure<ExecutiveDashboardVisibilityFilter>>());
    });
  });
}
