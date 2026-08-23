import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockTeamRepository extends Mock implements TeamRepository {}

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

void main() {
  group('UpdateTeamUseCase', () {
    late _MockTeamRepository teamRepository;
    late _MockMembershipRepository membershipRepository;
    late _MockOrganizationRepository organizationRepository;
    late UpdateTeamUseCase useCase;

    Team team({List<String> memberIds = const <String>['rep-old']}) {
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
      required String userId,
      required String roleName,
      List<String> teamIds = const <String>[],
    }) {
      return Membership(
        id: userId,
        organizationId: 'org-1',
        userId: userId,
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

    Organization organization() {
      return Organization(
        id: 'org-1',
        name: 'VestiPro',
        slug: 'vestipro',
        settings: const OrganizationSettings(
          currency: 'BRL',
          country: 'BR',
          defaultLanguage: 'pt-BR',
          maxTeamsPerUser: 3,
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
      useCase = UpdateTeamUseCase(
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
          userId: 'manager-1',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(
          membership(userId: 'manager-1', roleName: 'SALES_MANAGER'),
        ),
      );
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'rep-new',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(
          membership(
            userId: 'rep-new',
            roleName: 'SALES_ASSISTANT',
            teamIds: const <String>['team-other'],
          ),
        ),
      );
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'rep-old',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(
          membership(
            userId: 'rep-old',
            roleName: 'SALES_REP',
            teamIds: const <String>['team-1', 'team-other'],
          ),
        ),
      );
      when(
        () => organizationRepository.getById('org-1'),
      ).thenAnswer((_) async => AppSuccess<Organization>(organization()));
      when(
        () => teamRepository.update(
          organizationId: any(named: 'organizationId'),
          id: any(named: 'id'),
          name: any(named: 'name'),
          managerUserId: any(named: 'managerUserId'),
          memberIds: any(named: 'memberIds'),
          companyId: any(named: 'companyId'),
          branchId: any(named: 'branchId'),
          updatedBy: any(named: 'updatedBy'),
        ),
      ).thenAnswer(
        (_) async =>
            AppSuccess<Team>(team(memberIds: const <String>['rep-new'])),
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
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(
          membership(userId: 'rep-new', roleName: 'SALES_REP'),
        ),
      );
    });

    test(
      'updates team fields and realigns added/removed memberships',
      () async {
        final result = await useCase(
          organizationId: 'org-1',
          id: 'team-1',
          name: ' Equipe Sul Premium ',
          managerUserId: 'manager-1',
          memberIds: const <String>['rep-new'],
          updatedBy: 'manager-1',
        );

        expect(result, isA<AppSuccess<Team>>());
        verify(
          () => teamRepository.update(
            organizationId: 'org-1',
            id: 'team-1',
            name: 'Equipe Sul Premium',
            managerUserId: 'manager-1',
            memberIds: const <String>['rep-new'],
            companyId: null,
            branchId: null,
            updatedBy: 'manager-1',
          ),
        ).called(1);
        verify(
          () => membershipRepository.update(
            organizationId: 'org-1',
            userId: 'rep-new',
            roleId: 'SALES_ASSISTANT',
            roleName: 'SALES_ASSISTANT',
            teamIds: const <String>['team-other', 'team-1'],
            status: MembershipStatus.active,
            updatedBy: 'manager-1',
          ),
        ).called(1);
        verify(
          () => membershipRepository.update(
            organizationId: 'org-1',
            userId: 'rep-old',
            roleId: 'SALES_REP',
            roleName: 'SALES_REP',
            teamIds: const <String>['team-other'],
            status: MembershipStatus.active,
            updatedBy: 'manager-1',
          ),
        ).called(1);
      },
    );
  });
}
