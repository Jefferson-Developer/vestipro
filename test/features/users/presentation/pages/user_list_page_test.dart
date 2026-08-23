import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/users/users.dart';

import '../../../../core/design_system/components/test_pump_app.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockTeamRepository extends Mock implements TeamRepository {}

void main() {
  late _MockMembershipRepository membershipRepository;
  late _MockTeamRepository teamRepository;
  late PermissionService permissionService;

  Membership buildMembership({
    required String userId,
    required String roleName,
    String name = 'Ana Souza',
    String email = 'ana@vestipro.com.br',
    MembershipStatus status = MembershipStatus.active,
  }) {
    return Membership(
      id: userId,
      organizationId: 'org-1',
      userId: userId,
      roleId: roleName,
      roleName: roleName,
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
    permissionService = PermissionService(membershipRepository);
    when(
      () => teamRepository.listByOrganization('org-1'),
    ).thenAnswer((_) async => const AppSuccess<List<Team>>([]));
    when(() => membershipRepository.listByOrganization('org-1')).thenAnswer(
      (_) async => AppSuccess<List<Membership>>([
        buildMembership(
          userId: 'user-1',
          roleName: 'SALES_REP',
          name: 'Ana Souza',
          email: 'ana@vestipro.com.br',
        ),
        buildMembership(
          userId: 'user-2',
          roleName: 'SALES_MANAGER',
          name: 'Bruno Lima',
          email: 'bruno@vestipro.com.br',
        ),
      ]),
    );
  });

  Widget buildPage() {
    return UserListPage(
      organizationId: 'org-1',
      userId: 'current-user',
      permissionService: permissionService,
      createBloc: () => UserListBloc(
        listOrganizationUsers: ListOrganizationUsersUseCase(
          membershipRepository,
          teamRepository,
        ),
      ),
    );
  }

  void setWidth(WidgetTester tester, double width) {
    final view = tester.view;
    view.physicalSize = Size(width, 900);
    view.devicePixelRatio = 1.0;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);
  }

  group('UserListPage — RBAC', () {
    testWidgets(
      'hides the roster and shows the "sem permissão" fallback for a role '
      'without user.changeRole (e.g. SALES_REP)',
      (tester) async {
        setWidth(tester, 1200);
        when(
          () => membershipRepository.getByUser(
            organizationId: 'org-1',
            userId: 'current-user',
          ),
        ).thenAnswer(
          (_) async => AppSuccess<Membership>(
            buildMembership(userId: 'current-user', roleName: 'SALES_REP'),
          ),
        );

        await pumpApp(tester, buildPage());
        await tester.pumpAndSettle();

        expect(
          find.text('Você não tem permissão para acessar esta página.'),
          findsOneWidget,
        );
        expect(find.text('Usuários'), findsNothing);
        expect(find.text('Ana Souza'), findsNothing);
      },
    );

    testWidgets('renders the roster for an OWNER (has user.changeRole)', (
      tester,
    ) async {
      setWidth(tester, 1200);
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'current-user',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(
          buildMembership(userId: 'current-user', roleName: 'OWNER'),
        ),
      );

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Usuários'), findsOneWidget);
      expect(find.text('Ana Souza'), findsOneWidget);
      expect(find.text('Bruno Lima'), findsOneWidget);
    });
  });

  group('UserListPage — responsive layout', () {
    testWidgets('renders as an administrative table on desktop', (
      tester,
    ) async {
      setWidth(tester, 1300);
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'current-user',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(
          buildMembership(userId: 'current-user', roleName: 'OWNER'),
        ),
      );

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      // The table layout renders plain column headers ("E-mail", no
      // trailing colon) — only the card layout renders "E-mail: valor".
      expect(find.text('E-mail'), findsOneWidget);
      expect(find.textContaining('E-mail: '), findsNothing);
    });

    testWidgets('renders as cards on mobile', (tester) async {
      setWidth(tester, 360);
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'current-user',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(
          buildMembership(userId: 'current-user', roleName: 'OWNER'),
        ),
      );

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      // The card layout renders remaining columns as "Label: valor" — the
      // table layout never renders that colon-prefixed shape (same
      // convention exercised by AppDataTable's own tests).
      expect(find.textContaining('E-mail: '), findsNWidgets(2));
    });
  });

  group('UserListPage — empty/error states', () {
    testWidgets('shows an empty state when the organization has no users', (
      tester,
    ) async {
      setWidth(tester, 1200);
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'current-user',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(
          buildMembership(userId: 'current-user', roleName: 'OWNER'),
        ),
      );
      when(
        () => membershipRepository.listByOrganization('org-1'),
      ).thenAnswer((_) async => const AppSuccess<List<Membership>>([]));

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Nenhum usuário encontrado'), findsOneWidget);
    });
  });
}
