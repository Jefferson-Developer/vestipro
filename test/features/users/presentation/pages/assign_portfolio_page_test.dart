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

class _MockPortfolioAssignmentRepository extends Mock
    implements PortfolioAssignmentRepository {}

void main() {
  group('AssignPortfolioPage', () {
    late _MockMembershipRepository membershipRepository;
    late _MockTeamRepository teamRepository;
    late _MockPortfolioAssignmentRepository portfolioRepository;
    late PermissionService permissionService;
    late FakeAnalyticsService analyticsService;

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
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'owner-1',
      );
    }

    AssignPortfolioBloc buildBloc() {
      final listUsers = ListOrganizationUsersUseCase(
        membershipRepository,
        teamRepository,
      );
      return AssignPortfolioBloc(
        listOrganizationUsers: listUsers,
        listCommercialTeams: ListCommercialTeamsUseCase(
          teamRepository,
          listUsers,
        ),
        listPortfolioAssignments: ListPortfolioAssignmentsUseCase(
          portfolioRepository,
        ),
        assignPortfolio: AssignPortfolioUseCase(
          portfolioRepository,
          membershipRepository,
          teamRepository,
        ),
        analyticsService: analyticsService,
      );
    }

    Widget buildPage() {
      return AssignPortfolioPage(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'current-user',
        permissionService: permissionService,
        createBloc: buildBloc,
      );
    }

    setUp(() {
      membershipRepository = _MockMembershipRepository();
      teamRepository = _MockTeamRepository();
      portfolioRepository = _MockPortfolioAssignmentRepository();
      permissionService = PermissionService(membershipRepository);
      analyticsService = FakeAnalyticsService();

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
      ).thenAnswer((_) async => AppSuccess<List<Team>>([team()]));
      when(
        () => portfolioRepository.listActiveByOrganization(
          organizationId: 'org-1',
          companyId: 'company-1',
        ),
      ).thenAnswer(
        (_) async => const AppSuccess<List<PortfolioAssignment>>([]),
      );
    });

    testWidgets('renders the assignment form for OWNER', (tester) async {
      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Vínculo de carteira'), findsOneWidget);
      expect(find.byType(AppDropdown<String>), findsNWidgets(2));
      expect(find.byType(AppTextField), findsOneWidget);
      expect(find.text('Salvar vínculo'), findsOneWidget);
    });

    testWidgets('denies access to SALES_REP', (tester) async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'current-user',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(
          membership(userId: 'current-user', roleName: 'SALES_REP'),
        ),
      );

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Sem permissão'), findsOneWidget);
      expect(find.text('Salvar vínculo'), findsNothing);
    });
  });
}
