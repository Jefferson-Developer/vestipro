import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockTeamRepository extends Mock implements TeamRepository {}

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

void main() {
  group('AddMemberToTeamUseCase', () {
    late _MockTeamRepository teamRepository;
    late _MockMembershipRepository membershipRepository;
    late _MockOrganizationRepository organizationRepository;
    late AddMemberToTeamUseCase useCase;

    Team team({List<String> memberIds = const <String>[]}) {
      return Team(
        id: 'team-1',
        organizationId: 'org-1',
        name: 'Equipe Sul',
        managerUserId: 'manager-1',
        memberIds: memberIds,
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'owner-1',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'owner-1',
      );
    }

    Membership membership({
      List<String> teamIds = const <String>['team-other'],
      String roleName = 'SALES_REP',
    }) {
      return Membership(
        id: 'rep-1',
        organizationId: 'org-1',
        userId: 'rep-1',
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

    Organization organization({int? maxTeamsPerUser}) {
      return Organization(
        id: 'org-1',
        name: 'VestiPro',
        slug: 'vestipro',
        settings: OrganizationSettings(
          currency: 'BRL',
          country: 'BR',
          defaultLanguage: 'pt-BR',
          maxTeamsPerUser: maxTeamsPerUser,
        ),
        status: OrganizationStatus.active,
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
      organizationRepository = _MockOrganizationRepository();
      useCase = AddMemberToTeamUseCase(
        teamRepository,
        membershipRepository,
        organizationRepository,
      );
      when(
        () => teamRepository.getById(organizationId: 'org-1', id: 'team-1'),
      ).thenAnswer((_) async => AppSuccess<Team>(team()));
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'rep-1',
        ),
      ).thenAnswer((_) async => AppSuccess<Membership>(membership()));
      when(
        () => organizationRepository.getById('org-1'),
      ).thenAnswer((_) async => AppSuccess<Organization>(organization()));
      when(
        () => teamRepository.addMember(
          organizationId: any(named: 'organizationId'),
          id: any(named: 'id'),
          userId: any(named: 'userId'),
          updatedBy: any(named: 'updatedBy'),
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Team>(team(memberIds: const <String>['rep-1'])),
      );
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

    test('adds a member while preserving existing team memberships', () async {
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
          teamIds: const <String>['team-other', 'team-1'],
          status: MembershipStatus.active,
          updatedBy: 'manager-1',
        ),
      ).called(1);
    });

    test(
      'blocks assignment when organization maxTeamsPerUser is reached',
      () async {
        when(() => organizationRepository.getById('org-1')).thenAnswer(
          (_) async =>
              AppSuccess<Organization>(organization(maxTeamsPerUser: 1)),
        );

        final result = await useCase(
          organizationId: 'org-1',
          id: 'team-1',
          userId: 'rep-1',
          updatedBy: 'manager-1',
        );

        expect(result, isA<AppFailure<Team>>());
        expect((result as AppFailure<Team>).failure, isA<ConflictFailure>());
        verifyNever(
          () => teamRepository.addMember(
            organizationId: any(named: 'organizationId'),
            id: any(named: 'id'),
            userId: any(named: 'userId'),
            updatedBy: any(named: 'updatedBy'),
          ),
        );
      },
    );
  });
}
