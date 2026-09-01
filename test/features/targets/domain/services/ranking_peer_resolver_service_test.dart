import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/targets/targets.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockTeamRepository extends Mock implements TeamRepository {}

void main() {
  group('RankingPeerResolverService', () {
    late _MockMembershipRepository membershipRepository;
    late _MockTeamRepository teamRepository;
    late RankingPeerResolverService service;

    setUp(() {
      membershipRepository = _MockMembershipRepository();
      teamRepository = _MockTeamRepository();
      service = RankingPeerResolverService(
        membershipRepository,
        teamRepository,
      );
    });

    Membership buildMembership(
      String userId,
      String roleName, {
      List<String> teamIds = const <String>[],
      MembershipStatus status = MembershipStatus.active,
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
        createdBy: userId,
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: userId,
      );
    }

    Team buildTeam(String id, {List<String> memberIds = const <String>[]}) {
      return Team(
        id: id,
        organizationId: 'org-1',
        name: 'Team $id',
        managerUserId: 'manager-1',
        memberIds: memberIds,
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'owner-1',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'owner-1',
      );
    }

    group('RankingDimensionType.salesRep', () {
      test('OWNER/ADMIN (allOrganization): peers are every active SALES_REP '
          'membership of the organization — never a SALES_MANAGER/ADMIN/'
          'inactive one', () async {
        when(() => membershipRepository.listByOrganization('org-1')).thenAnswer(
          (_) async => AppSuccess<List<Membership>>(<Membership>[
            buildMembership('rep-1', 'SALES_REP'),
            buildMembership('rep-2', 'SALES_REP'),
            buildMembership('manager-1', 'SALES_MANAGER'),
            buildMembership(
              'rep-inactive',
              'SALES_REP',
              status: MembershipStatus.inactive,
            ),
          ]),
        );

        final result = await service.resolve(
          organizationId: 'org-1',
          userId: 'owner-1',
          dimensionType: RankingDimensionType.salesRep,
          visibilityFilter: const TargetVisibilityFilter(
            organizationId: 'org-1',
            companyId: 'company-1',
            userId: 'owner-1',
            mode: TargetVisibilityMode.allOrganization,
          ),
        );

        final scope = (result as AppSuccess<RankingPeerScope>).value;
        expect(scope.peerIds, <String>{'rep-1', 'rep-2'});
      });

      test('SALES_MANAGER (teams): peers are exactly '
          'TargetVisibilityFilter.teamMemberIds — never re-derived', () async {
        final result = await service.resolve(
          organizationId: 'org-1',
          userId: 'manager-1',
          dimensionType: RankingDimensionType.salesRep,
          visibilityFilter: const TargetVisibilityFilter(
            organizationId: 'org-1',
            companyId: 'company-1',
            userId: 'manager-1',
            mode: TargetVisibilityMode.teams,
            teamIds: <String>{'team-a'},
            teamMemberIds: <String>{'rep-1', 'rep-2'},
          ),
        );

        final scope = (result as AppSuccess<RankingPeerScope>).value;
        expect(scope.peerIds, <String>{'rep-1', 'rep-2'});
        verifyNever(() => membershipRepository.listByOrganization(any()));
      });

      test('SALES_REP (ownOnly): peers are every member of every Team the '
          'caller belongs to — never a stranger from another team', () async {
        when(() => teamRepository.listByOrganization('org-1')).thenAnswer(
          (_) async => AppSuccess<List<Team>>(<Team>[
            buildTeam('team-a', memberIds: <String>['rep-1', 'rep-2']),
            buildTeam('team-b', memberIds: <String>['rep-3']),
          ]),
        );

        final result = await service.resolve(
          organizationId: 'org-1',
          userId: 'rep-1',
          dimensionType: RankingDimensionType.salesRep,
          visibilityFilter: const TargetVisibilityFilter(
            organizationId: 'org-1',
            companyId: 'company-1',
            userId: 'rep-1',
            mode: TargetVisibilityMode.ownOnly,
          ),
        );

        final scope = (result as AppSuccess<RankingPeerScope>).value;
        expect(scope.peerIds, <String>{'rep-1', 'rep-2'});
        expect(
          scope.peerIds.contains('rep-3'),
          isFalse,
          reason: 'rep-3 belongs to team-b, not the caller\'s team.',
        );
      });

      test('SALES_REP (ownOnly) in no Team yet: peers are just the caller — a '
          'ranking of one, never an empty scope', () async {
        when(
          () => teamRepository.listByOrganization('org-1'),
        ).thenAnswer((_) async => const AppSuccess<List<Team>>(<Team>[]));

        final result = await service.resolve(
          organizationId: 'org-1',
          userId: 'rep-1',
          dimensionType: RankingDimensionType.salesRep,
          visibilityFilter: const TargetVisibilityFilter(
            organizationId: 'org-1',
            companyId: 'company-1',
            userId: 'rep-1',
            mode: TargetVisibilityMode.ownOnly,
          ),
        );

        final scope = (result as AppSuccess<RankingPeerScope>).value;
        expect(scope.peerIds, <String>{'rep-1'});
      });

      test('none: peers are empty — never queries anything', () async {
        final result = await service.resolve(
          organizationId: 'org-1',
          userId: 'stranger',
          dimensionType: RankingDimensionType.salesRep,
          visibilityFilter: const TargetVisibilityFilter.none(
            organizationId: 'org-1',
            companyId: 'company-1',
            userId: 'stranger',
          ),
        );

        final scope = (result as AppSuccess<RankingPeerScope>).value;
        expect(scope.isEmpty, isTrue);
        verifyNever(() => membershipRepository.listByOrganization(any()));
        verifyNever(() => teamRepository.listByOrganization(any()));
      });
    });

    group('RankingDimensionType.team', () {
      test('OWNER/ADMIN (allOrganization): peers are every Team of the '
          'organization', () async {
        when(() => teamRepository.listByOrganization('org-1')).thenAnswer(
          (_) async => AppSuccess<List<Team>>(<Team>[
            buildTeam('team-a'),
            buildTeam('team-b'),
          ]),
        );

        final result = await service.resolve(
          organizationId: 'org-1',
          userId: 'owner-1',
          dimensionType: RankingDimensionType.team,
          visibilityFilter: const TargetVisibilityFilter(
            organizationId: 'org-1',
            companyId: 'company-1',
            userId: 'owner-1',
            mode: TargetVisibilityMode.allOrganization,
          ),
        );

        final scope = (result as AppSuccess<RankingPeerScope>).value;
        expect(scope.peerIds, <String>{'team-a', 'team-b'});
      });

      test('SALES_MANAGER (teams): peers are exactly the managed teamIds — '
          'never every team of the organization', () async {
        final result = await service.resolve(
          organizationId: 'org-1',
          userId: 'manager-1',
          dimensionType: RankingDimensionType.team,
          visibilityFilter: const TargetVisibilityFilter(
            organizationId: 'org-1',
            companyId: 'company-1',
            userId: 'manager-1',
            mode: TargetVisibilityMode.teams,
            teamIds: <String>{'team-a'},
            teamMemberIds: <String>{'rep-1'},
          ),
        );

        final scope = (result as AppSuccess<RankingPeerScope>).value;
        expect(scope.peerIds, <String>{'team-a'});
        verifyNever(() => teamRepository.listByOrganization(any()));
      });

      test('SALES_REP (ownOnly) requesting a team ranking: empty scope — a '
          'SALES_REP never ranks by team, defense-in-depth even if the UI '
          'somehow requests it', () async {
        final result = await service.resolve(
          organizationId: 'org-1',
          userId: 'rep-1',
          dimensionType: RankingDimensionType.team,
          visibilityFilter: const TargetVisibilityFilter(
            organizationId: 'org-1',
            companyId: 'company-1',
            userId: 'rep-1',
            mode: TargetVisibilityMode.ownOnly,
          ),
        );

        final scope = (result as AppSuccess<RankingPeerScope>).value;
        expect(scope.isEmpty, isTrue);
        verifyNever(() => teamRepository.listByOrganization(any()));
      });
    });

    test('propagates a repository failure instead of silently returning an '
        'empty scope', () async {
      when(() => membershipRepository.listByOrganization('org-1')).thenAnswer(
        (_) async =>
            const AppFailure<List<Membership>>(ConnectivityFailure('offline')),
      );

      final result = await service.resolve(
        organizationId: 'org-1',
        userId: 'owner-1',
        dimensionType: RankingDimensionType.salesRep,
        visibilityFilter: const TargetVisibilityFilter(
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'owner-1',
          mode: TargetVisibilityMode.allOrganization,
        ),
      );

      expect(result, isA<AppFailure<RankingPeerScope>>());
    });
  });
}
