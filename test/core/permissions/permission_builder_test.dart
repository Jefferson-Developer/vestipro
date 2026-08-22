import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

void main() {
  group('PermissionBuilder', () {
    late _MockMembershipRepository membershipRepository;
    late PermissionService permissionService;

    Membership buildMembership(String roleName) {
      return Membership(
        id: 'user-1',
        organizationId: 'org-1',
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
      membershipRepository = _MockMembershipRepository();
      permissionService = PermissionService(membershipRepository);
    });

    testWidgets('renders the granted branch once the capability is confirmed', (
      tester,
    ) async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'user-1',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(buildMembership('SALES_MANAGER')),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PermissionBuilder(
            permissionService: permissionService,
            organizationId: 'org-1',
            userId: 'user-1',
            capability: Capability.orderApprove,
            builder: (context, granted) => Text(granted ? 'granted' : 'denied'),
          ),
        ),
      );

      expect(find.text('denied'), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.text('granted'), findsOneWidget);
      expect(find.text('denied'), findsNothing);
    });

    testWidgets('renders the denied branch when the capability is not '
        'granted', (tester) async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'user-1',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(buildMembership('READ_ONLY')),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PermissionBuilder(
            permissionService: permissionService,
            organizationId: 'org-1',
            userId: 'user-1',
            capability: Capability.orderApprove,
            builder: (context, granted) => Text(granted ? 'granted' : 'denied'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('denied'), findsOneWidget);
    });

    testWidgets(
      'fails closed (denied) when PermissionService resolution fails',
      (tester) async {
        when(
          () => membershipRepository.getByUser(
            organizationId: 'org-1',
            userId: 'user-1',
          ),
        ).thenAnswer(
          (_) async =>
              AppFailure<Membership>(const ConnectivityFailure('offline')),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: PermissionBuilder(
              permissionService: permissionService,
              organizationId: 'org-1',
              userId: 'user-1',
              capability: Capability.orderApprove,
              builder: (context, granted) =>
                  Text(granted ? 'granted' : 'denied'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('denied'), findsOneWidget);
      },
    );

    testWidgets('uses placeholderBuilder while the check is in flight', (
      tester,
    ) async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'user-1',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(buildMembership('SALES_MANAGER')),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PermissionBuilder(
            permissionService: permissionService,
            organizationId: 'org-1',
            userId: 'user-1',
            capability: Capability.orderApprove,
            placeholderBuilder: (context) => const Text('loading'),
            builder: (context, granted) => Text(granted ? 'granted' : 'denied'),
          ),
        ),
      );

      expect(find.text('loading'), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.text('granted'), findsOneWidget);
    });
  });
}
