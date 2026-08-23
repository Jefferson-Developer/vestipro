import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/auth/auth.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/users/users.dart';

import '../../../../core/design_system/components/test_pump_app.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockUserRoleRepository extends Mock implements UserRoleRepository {}

void main() {
  group('UserRoleEditPage', () {
    const signedInUser = SessionUser(uid: 'current-user', emailVerified: true);

    late _MockAuthRepository authRepository;
    late _MockMembershipRepository membershipRepository;
    late _MockUserRoleRepository userRoleRepository;
    late FakeAnalyticsService analyticsService;

    OrganizationUser user({
      String userId = 'rep-1',
      String roleName = 'SALES_REP',
      String name = 'Bruno Lima',
    }) {
      return OrganizationUser(
        userId: userId,
        name: name,
        email: '$userId@vestipro.com.br',
        roleName: roleName,
        status: MembershipStatus.active,
      );
    }

    Membership membership(String roleName) {
      return Membership(
        id: 'current-user',
        organizationId: 'org-1',
        userId: 'current-user',
        roleId: roleName,
        roleName: roleName,
        status: MembershipStatus.active,
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'owner-1',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'owner-1',
      );
    }

    UserRoleEditBloc buildBloc() {
      return UserRoleEditBloc(
        updateUserRole: UpdateUserRoleUseCase(userRoleRepository),
        membershipRepository: membershipRepository,
        authRepository: authRepository,
        analyticsService: analyticsService,
      );
    }

    Widget buildPage(OrganizationUser target) {
      return UserRoleEditPage(
        organizationId: 'org-1',
        user: target,
        createBloc: buildBloc,
      );
    }

    Future<void> selectRole(WidgetTester tester, String label) async {
      await tester.tap(find.byType(AppDropdown<SystemRoleName>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
    }

    setUpAll(() {
      registerFallbackValue(SystemRoleName.owner);
    });

    setUp(() {
      authRepository = _MockAuthRepository();
      membershipRepository = _MockMembershipRepository();
      userRoleRepository = _MockUserRoleRepository();
      analyticsService = FakeAnalyticsService();
      when(() => authRepository.currentUser).thenReturn(signedInUser);
    });

    testWidgets('restricts the role selector to roles the caller can assign', (
      tester,
    ) async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'current-user',
        ),
      ).thenAnswer((_) async => AppSuccess<Membership>(membership('ADMIN')));

      await pumpApp(tester, buildPage(user()));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(AppDropdown<SystemRoleName>));
      await tester.pumpAndSettle();

      expect(find.text('Administrador (ADMIN)'), findsOneWidget);
      expect(find.text('Proprietário (OWNER)'), findsNothing);
    });

    testWidgets('asks for confirmation before a sensitive role change', (
      tester,
    ) async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'current-user',
        ),
      ).thenAnswer((_) async => AppSuccess<Membership>(membership('OWNER')));

      await pumpApp(tester, buildPage(user()));
      await tester.pumpAndSettle();
      await selectRole(tester, 'Administrador (ADMIN)');
      await tester.tap(find.text('Salvar alteração'));
      await tester.pumpAndSettle();

      expect(find.text('Confirmar alteração sensível?'), findsOneWidget);
      verifyNever(
        () => userRoleRepository.updateUserRole(
          organizationId: any(named: 'organizationId'),
          targetUserId: any(named: 'targetUserId'),
          roleName: any(named: 'roleName'),
        ),
      );
    });

    testWidgets('shows a clear last OWNER error when the backend blocks it', (
      tester,
    ) async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'current-user',
        ),
      ).thenAnswer((_) async => AppSuccess<Membership>(membership('OWNER')));
      when(
        () => userRoleRepository.updateUserRole(
          organizationId: any(named: 'organizationId'),
          targetUserId: any(named: 'targetUserId'),
          roleName: any(named: 'roleName'),
        ),
      ).thenAnswer(
        (_) async => AppFailure<UserRoleUpdateResult>(
          const ConflictFailure(
            'Não é possível alterar este perfil porque ele é o último OWNER ativo da organização.',
          ),
        ),
      );

      await pumpApp(
        tester,
        buildPage(
          user(userId: 'owner-1', roleName: 'OWNER', name: 'Ana Souza'),
        ),
      );
      await tester.pumpAndSettle();
      await selectRole(tester, 'Administrador (ADMIN)');
      await tester.tap(find.text('Salvar alteração'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar alteração'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Não é possível alterar este perfil porque ele é o último OWNER ativo da organização.',
        ),
        findsOneWidget,
      );
    });
  });
}
