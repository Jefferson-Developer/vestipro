import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/users/users.dart';

import '../../../../core/design_system/components/test_pump_app.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockTeamRepository extends Mock implements TeamRepository {}

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

void main() {
  group('TeamListPage', () {
    late _MockMembershipRepository membershipRepository;
    late _MockTeamRepository teamRepository;
    late _MockOrganizationRepository organizationRepository;
    late FakeAnalyticsService analyticsService;
    late PermissionService permissionService;

    Membership membership({
      required String userId,
      required String roleName,
      String name = 'Ana Souza',
      String email = 'ana@vestipro.com.br',
    }) {
      return Membership(
        id: userId,
        organizationId: 'org-1',
        userId: userId,
        roleId: roleName,
        roleName: roleName,
        status: MembershipStatus.active,
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'owner-1',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'owner-1',
        name: name,
        email: email,
      );
    }

    Team team() {
      return Team(
        id: 'team-1',
        organizationId: 'org-1',
        name: 'Equipe Sul',
        managerUserId: 'manager-1',
        memberIds: const <String>['rep-1'],
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'owner-1',
        updatedAt: DateTime.utc(2026, 1, 2),
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
        ),
        status: OrganizationStatus.active,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'owner-1',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'owner-1',
      );
    }

    TeamFormBloc buildFormBloc() {
      return TeamFormBloc(
        listOrganizationUsers: ListOrganizationUsersUseCase(
          membershipRepository,
          teamRepository,
        ),
        createTeam: CreateTeamUseCase(
          teamRepository,
          membershipRepository,
          organizationRepository,
        ),
        updateTeam: UpdateTeamUseCase(
          teamRepository,
          membershipRepository,
          organizationRepository,
        ),
        analyticsService: analyticsService,
      );
    }

    TeamListBloc buildListBloc() {
      return TeamListBloc(
        listCommercialTeams: ListCommercialTeamsUseCase(
          teamRepository,
          ListOrganizationUsersUseCase(membershipRepository, teamRepository),
        ),
        deleteTeam: DeleteTeamUseCase(teamRepository),
        analyticsService: analyticsService,
      );
    }

    Widget buildPage() {
      return TeamListPage(
        organizationId: 'org-1',
        userId: 'current-user',
        permissionService: permissionService,
        createBloc: buildListBloc,
        createFormBloc: buildFormBloc,
      );
    }

    void setWidth(WidgetTester tester, double width) {
      final view = tester.view;
      view.physicalSize = Size(width, 900);
      view.devicePixelRatio = 1.0;
      addTearDown(view.resetPhysicalSize);
      addTearDown(view.resetDevicePixelRatio);
    }

    setUp(() {
      membershipRepository = _MockMembershipRepository();
      teamRepository = _MockTeamRepository();
      organizationRepository = _MockOrganizationRepository();
      analyticsService = FakeAnalyticsService();
      permissionService = PermissionService(membershipRepository);
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'current-user',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(
          membership(userId: 'current-user', roleName: 'OWNER'),
        ),
      );
      when(() => membershipRepository.listByOrganization('org-1')).thenAnswer(
        (_) async => AppSuccess<List<Membership>>([
          membership(
            userId: 'manager-1',
            roleName: 'SALES_MANAGER',
            name: 'Bruno Lima',
            email: 'bruno@vestipro.com.br',
          ),
          membership(userId: 'rep-1', roleName: 'SALES_REP'),
        ]),
      );
      when(
        () => teamRepository.listByOrganization('org-1'),
      ).thenAnswer((_) async => const AppSuccess<List<Team>>([]));
      when(
        () => organizationRepository.getById('org-1'),
      ).thenAnswer((_) async => AppSuccess<Organization>(organization()));
    });

    testWidgets('shows an empty state guiding the first team creation', (
      tester,
    ) async {
      setWidth(tester, 1200);

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma equipe comercial criada'), findsOneWidget);
      expect(find.text('Criar primeira equipe'), findsOneWidget);
    });

    testWidgets('renders existing teams with manager and member count', (
      tester,
    ) async {
      setWidth(tester, 1200);
      when(
        () => teamRepository.listByOrganization('org-1'),
      ).thenAnswer((_) async => AppSuccess<List<Team>>([team()]));

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Equipe Sul'), findsOneWidget);
      expect(find.text('Bruno Lima'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });
  });
}
