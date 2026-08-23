import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/design_system/design_system.dart';
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
  group('TeamFormPage', () {
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
        name: name,
        email: email,
      );
    }

    Team team({
      String id = 'team-1',
      String name = 'Equipe Sul',
      String managerUserId = 'manager-1',
      List<String> memberIds = const <String>['rep-1'],
    }) {
      return Team(
        id: id,
        organizationId: 'org-1',
        name: name,
        managerUserId: managerUserId,
        memberIds: memberIds,
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'current-user',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'current-user',
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

    TeamFormBloc buildBloc() {
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

    Widget buildPage({Team? initialTeam}) {
      return TeamFormPage(
        organizationId: 'org-1',
        userId: 'current-user',
        permissionService: permissionService,
        createBloc: buildBloc,
        initialTeam: initialTeam,
      );
    }

    setUpAll(() {
      registerFallbackValue(MembershipStatus.active);
    });

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
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'manager-1',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(
          membership(
            userId: 'manager-1',
            roleName: 'SALES_MANAGER',
            name: 'Bruno Lima',
            email: 'bruno@vestipro.com.br',
          ),
        ),
      );
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'rep-1',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(
          membership(userId: 'rep-1', roleName: 'SALES_REP'),
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
          membership(userId: 'rep-1', roleName: 'SALES_REP'),
        ),
      );
    });

    testWidgets('validates that manager is required', (tester) async {
      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'Equipe Sul');
      await tester.tap(find.text('Criar equipe'));
      await tester.pumpAndSettle();

      expect(find.text('Selecione um gestor responsável.'), findsOneWidget);
      verifyNever(
        () => teamRepository.create(
          id: any(named: 'id'),
          organizationId: any(named: 'organizationId'),
          name: any(named: 'name'),
          managerUserId: any(named: 'managerUserId'),
          memberIds: any(named: 'memberIds'),
          companyId: any(named: 'companyId'),
          branchId: any(named: 'branchId'),
          createdBy: any(named: 'createdBy'),
        ),
      );
    });

    testWidgets('creates a team with manager and multi-selected members', (
      tester,
    ) async {
      when(
        () => teamRepository.create(
          id: any(named: 'id'),
          organizationId: any(named: 'organizationId'),
          name: any(named: 'name'),
          managerUserId: any(named: 'managerUserId'),
          memberIds: any(named: 'memberIds'),
          companyId: any(named: 'companyId'),
          branchId: any(named: 'branchId'),
          createdBy: any(named: 'createdBy'),
        ),
      ).thenAnswer((_) async => AppSuccess<Team>(team()));

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'Equipe Sul');
      await tester.tap(find.byType(AppDropdown<String>).at(0));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Bruno Lima').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(AppDropdown<String>).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Ana Souza').last);
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Fechar seleção de membros'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Criar equipe'));
      await tester.pumpAndSettle();

      verify(
        () => teamRepository.create(
          id: any(named: 'id'),
          organizationId: 'org-1',
          name: 'Equipe Sul',
          managerUserId: 'manager-1',
          memberIds: const <String>['rep-1'],
          companyId: null,
          branchId: null,
          createdBy: 'current-user',
        ),
      ).called(1);
      expect(
        analyticsService.loggedEvents.last.name,
        AnalyticsEvents.teamCreated,
      );
    });

    testWidgets('edits an existing team', (tester) async {
      when(
        () => teamRepository.getById(organizationId: 'org-1', id: 'team-1'),
      ).thenAnswer((_) async => AppSuccess<Team>(team()));
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
        (_) async => AppSuccess<Team>(team(name: 'Equipe Sul Premium')),
      );

      await pumpApp(tester, buildPage(initialTeam: team()));
      await tester.pumpAndSettle();

      expect(find.text('Editar equipe'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'Equipe Sul Premium');
      await tester.tap(find.text('Salvar alterações'));
      await tester.pumpAndSettle();

      verify(
        () => teamRepository.update(
          organizationId: 'org-1',
          id: 'team-1',
          name: 'Equipe Sul Premium',
          managerUserId: 'manager-1',
          memberIds: const <String>['rep-1'],
          companyId: null,
          branchId: null,
          updatedBy: 'current-user',
        ),
      ).called(1);
      expect(
        analyticsService.loggedEvents.last.name,
        AnalyticsEvents.teamUpdated,
      );
    });
  });
}
