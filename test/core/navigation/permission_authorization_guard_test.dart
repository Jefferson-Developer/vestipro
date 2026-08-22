import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/auth/auth.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/navigation/navigation.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockMembershipRepository extends Mock implements MembershipRepository {}

void main() {
  group('PermissionAuthorizationGuard', () {
    late _MockAuthRepository authRepository;
    late _MockMembershipRepository membershipRepository;
    late PermissionService permissionService;
    late PermissionAuthorizationGuard guard;

    const signedInUser = SessionUser(uid: 'user-1', emailVerified: true);

    Membership buildMembership(String roleName) {
      return Membership(
        id: 'user-1',
        organizationId: 'acme',
        userId: 'user-1',
        roleId: roleName,
        roleName: roleName,
        status: MembershipStatus.active,
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'user-1',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'user-1',
      );
    }

    setUp(() {
      authRepository = _MockAuthRepository();
      membershipRepository = _MockMembershipRepository();
      permissionService = PermissionService(membershipRepository);
      guard = PermissionAuthorizationGuard(permissionService, authRepository);
    });

    testWidgets(
      'allows navigation when the active Membership grants the required '
      'capability',
      (tester) async {
        when(() => authRepository.currentUser).thenReturn(signedInUser);
        when(
          () => membershipRepository.getByUser(
            organizationId: 'acme',
            userId: 'user-1',
          ),
        ).thenAnswer(
          (_) async => AppSuccess<Membership>(buildMembership('SALES_MANAGER')),
        );

        final router = _buildRouter(guard);
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        router.go('/org/acme/orders/approve');
        await tester.pumpAndSettle();

        expect(find.text('approve-order:acme'), findsOneWidget);
      },
    );

    testWidgets(
      'redirects to ForbiddenRoute when the active Membership does not '
      'grant the required capability',
      (tester) async {
        when(() => authRepository.currentUser).thenReturn(signedInUser);
        when(
          () => membershipRepository.getByUser(
            organizationId: 'acme',
            userId: 'user-1',
          ),
        ).thenAnswer(
          (_) async => AppSuccess<Membership>(buildMembership('SALES_REP')),
        );

        final router = _buildRouter(guard);
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        router.go('/org/acme/orders/approve');
        await tester.pumpAndSettle();

        expect(find.text('approve-order:acme'), findsNothing);
        expect(find.text('forbidden'), findsOneWidget);
      },
    );

    testWidgets('redirects to ForbiddenRoute when no session is signed in', (
      tester,
    ) async {
      when(() => authRepository.currentUser).thenReturn(null);

      final router = _buildRouter(guard);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.go('/org/acme/orders/approve');
      await tester.pumpAndSettle();

      expect(find.text('approve-order:acme'), findsNothing);
      expect(find.text('forbidden'), findsOneWidget);
      verifyNever(
        () => membershipRepository.getByUser(
          organizationId: any(named: 'organizationId'),
          userId: any(named: 'userId'),
        ),
      );
    });

    testWidgets(
      'fails closed to ForbiddenRoute when PermissionService cannot resolve '
      'the Membership',
      (tester) async {
        when(() => authRepository.currentUser).thenReturn(signedInUser);
        when(
          () => membershipRepository.getByUser(
            organizationId: 'acme',
            userId: 'user-1',
          ),
        ).thenAnswer(
          (_) async =>
              AppFailure<Membership>(const ConnectivityFailure('offline')),
        );

        final router = _buildRouter(guard);
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        router.go('/org/acme/orders/approve');
        await tester.pumpAndSettle();

        expect(find.text('approve-order:acme'), findsNothing);
        expect(find.text('forbidden'), findsOneWidget);
      },
    );
  });
}

GoRouter _buildRouter(PermissionAuthorizationGuard guard) {
  return GoRouter(
    initialLocation: '/org/acme/orders',
    routes: [
      GoRoute(
        path: '/org/:orgId/orders',
        builder: (context, state) => const Scaffold(body: Text('orders')),
      ),
      GoRoute(
        path: '/org/:orgId/orders/approve',
        redirect: (context, state) => guard.redirect(
          context,
          state,
          requiredCapability: Capability.orderApprove,
        ),
        builder: (context, state) => Scaffold(
          body: Text('approve-order:${state.pathParameters['orgId']}'),
        ),
      ),
      GoRoute(
        path: ForbiddenRoute.pathPattern,
        builder: (context, state) => const Scaffold(body: Text('forbidden')),
      ),
    ],
  );
}
