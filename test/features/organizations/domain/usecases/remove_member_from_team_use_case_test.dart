import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockTeamRepository extends Mock implements TeamRepository {}

class _MockMembershipRepository extends Mock implements MembershipRepository {}

void main() {
  group('RemoveMemberFromTeamUseCase', () {
    late _MockTeamRepository teamRepository;
    late _MockMembershipRepository membershipRepository;
    late RemoveMemberFromTeamUseCase useCase;

    Team team() {
      return Team(
        id: 'team-1',
        organizationId: 'org-1',
        name: 'Equipe Sul',
        managerUserId: 'manager-1',
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'owner-1',
        updatedAt: DateTime.utc(2026, 1, 2),
        updatedBy: 'manager-1',
      );
    }

    Membership membership() {
      return Membership(
        id: 'rep-1',
        organizationId: 'org-1',
        userId: 'rep-1',
        roleId: 'SALES_REP',
        roleName: 'SALES_REP',
        teamIds: const <String>['team-other', 'team-1'],
        status: MembershipStatus.active,
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'owner-1',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'owner-1',
      );
    }

    setUpAll(() {
      registerFallbackValue(MembershipStatus.active);
    });

    setUp(() {
      teamRepository = _MockTeamRepository();
      membershipRepository = _MockMembershipRepository();
      useCase = RemoveMemberFromTeamUseCase(
        teamRepository,
        membershipRepository,
      );
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'rep-1',
        ),
      ).thenAnswer((_) async => AppSuccess<Membership>(membership()));
      when(
        () => teamRepository.removeMember(
          organizationId: any(named: 'organizationId'),
          id: any(named: 'id'),
          userId: any(named: 'userId'),
          updatedBy: any(named: 'updatedBy'),
        ),
      ).thenAnswer((_) async => AppSuccess<Team>(team()));
      when(
        () => membershipRepository.update(
          organizationId: any(named: 'organizationId'),
          userId: any(named: 'userId'),
          roleId: any(named: 'roleId'),
          roleName: any(named: 'roleName'),
          teamIds: any(named: 'teamIds'),
          status: any(named: 'status'),
          updatedBy: any(named: 'updatedBy'),
        ),
      ).thenAnswer((_) async => AppSuccess<Membership>(membership()));
    });

    test('removes only the requested team from Membership.teamIds', () async {
      final result = await useCase(
        organizationId: 'org-1',
        id: 'team-1',
        userId: 'rep-1',
        updatedBy: 'manager-1',
      );

      expect(result, isA<AppSuccess<Team>>());
      verify(
        () => membershipRepository.update(
          organizationId: 'org-1',
          userId: 'rep-1',
          roleId: 'SALES_REP',
          roleName: 'SALES_REP',
          teamIds: const <String>['team-other'],
          status: MembershipStatus.active,
          updatedBy: 'manager-1',
        ),
      ).called(1);
    });
  });
}
