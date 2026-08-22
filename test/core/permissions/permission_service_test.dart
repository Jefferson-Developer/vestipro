import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

void main() {
  group('PermissionService', () {
    late _MockMembershipRepository membershipRepository;
    late PermissionService service;

    Membership buildMembership({
      String roleName = 'SALES_REP',
      MembershipStatus status = MembershipStatus.active,
    }) {
      return Membership(
        id: 'user-1',
        organizationId: 'org-1',
        userId: 'user-1',
        roleId: roleName,
        roleName: roleName,
        status: status,
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'user-1',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'user-1',
      );
    }

    setUp(() {
      membershipRepository = _MockMembershipRepository();
      service = PermissionService(membershipRepository);
    });

    test(
      'hasPermission returns true for a capability the resolved role grants',
      () async {
        when(
          () => membershipRepository.getByUser(
            organizationId: 'org-1',
            userId: 'user-1',
          ),
        ).thenAnswer(
          (_) async =>
              AppSuccess<Membership>(buildMembership(roleName: 'SALES_REP')),
        );

        final result = await service.hasPermission(
          organizationId: 'org-1',
          userId: 'user-1',
          capability: Capability.customerCreate,
        );

        expect(result, isA<AppSuccess<bool>>());
        expect((result as AppSuccess<bool>).value, isTrue);
      },
    );

    test('hasPermission returns false for a capability the resolved role does '
        'not grant', () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'user-1',
        ),
      ).thenAnswer(
        (_) async =>
            AppSuccess<Membership>(buildMembership(roleName: 'SALES_REP')),
      );

      final result = await service.hasPermission(
        organizationId: 'org-1',
        userId: 'user-1',
        capability: Capability.orderApprove,
      );

      expect(result, isA<AppSuccess<bool>>());
      expect((result as AppSuccess<bool>).value, isFalse);
    });

    test('hasPermission returns false, not a Failure, when the user has no '
        'Membership in the organization', () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'stranger',
        ),
      ).thenAnswer(
        (_) async => AppFailure<Membership>(
          const NotFoundFailure(
            'Membership not found.',
            code: 'membership_not_found',
          ),
        ),
      );

      final result = await service.hasPermission(
        organizationId: 'org-1',
        userId: 'stranger',
        capability: Capability.customerCreate,
      );

      expect(result, isA<AppSuccess<bool>>());
      expect((result as AppSuccess<bool>).value, isFalse);
    });

    test('hasPermission returns false for an inactive Membership, even for a '
        'role that would otherwise grant the capability', () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'user-1',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(
          buildMembership(roleName: 'OWNER', status: MembershipStatus.inactive),
        ),
      );

      final result = await service.hasPermission(
        organizationId: 'org-1',
        userId: 'user-1',
        capability: Capability.customerCreate,
      );

      expect(result, isA<AppSuccess<bool>>());
      expect((result as AppSuccess<bool>).value, isFalse);
    });

    test(
      'hasPermission propagates a non-NotFound repository Failure instead of '
      'silently denying',
      () async {
        when(
          () => membershipRepository.getByUser(
            organizationId: 'org-1',
            userId: 'user-1',
          ),
        ).thenAnswer(
          (_) async => AppFailure<Membership>(
            const ConnectivityFailure('No connection.'),
          ),
        );

        final result = await service.hasPermission(
          organizationId: 'org-1',
          userId: 'user-1',
          capability: Capability.customerCreate,
        );

        expect(result, isA<AppFailure<bool>>());
        expect(
          (result as AppFailure<bool>).failure,
          isA<ConnectivityFailure>(),
        );
      },
    );

    test('READ_ONLY never resolves true for any capability', () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'user-1',
        ),
      ).thenAnswer(
        (_) async =>
            AppSuccess<Membership>(buildMembership(roleName: 'READ_ONLY')),
      );

      for (final capability in Capability.values) {
        final result = await service.hasPermission(
          organizationId: 'org-1',
          userId: 'user-1',
          capability: capability,
        );

        expect((result as AppSuccess<bool>).value, isFalse);
      }
    });

    test('hasAnyPermission returns true when at least one of the capabilities '
        'is granted', () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'user-1',
        ),
      ).thenAnswer(
        (_) async =>
            AppSuccess<Membership>(buildMembership(roleName: 'SALES_REP')),
      );

      final result = await service.hasAnyPermission(
        organizationId: 'org-1',
        userId: 'user-1',
        capabilities: const <Capability>[
          Capability.orderApprove,
          Capability.customerCreate,
        ],
      );

      expect((result as AppSuccess<bool>).value, isTrue);
    });

    test('hasAnyPermission returns false when none of the capabilities are '
        'granted', () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'user-1',
        ),
      ).thenAnswer(
        (_) async =>
            AppSuccess<Membership>(buildMembership(roleName: 'READ_ONLY')),
      );

      final result = await service.hasAnyPermission(
        organizationId: 'org-1',
        userId: 'user-1',
        capabilities: const <Capability>[
          Capability.orderApprove,
          Capability.customerCreate,
        ],
      );

      expect((result as AppSuccess<bool>).value, isFalse);
    });

    test('a role change is reflected on the very next check, with no stale '
        'cache from a previous resolution', () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'user-1',
        ),
      ).thenAnswer(
        (_) async =>
            AppSuccess<Membership>(buildMembership(roleName: 'SALES_REP')),
      );

      final beforePromotion = await service.hasPermission(
        organizationId: 'org-1',
        userId: 'user-1',
        capability: Capability.orderApprove,
      );
      expect((beforePromotion as AppSuccess<bool>).value, isFalse);

      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'user-1',
        ),
      ).thenAnswer(
        (_) async =>
            AppSuccess<Membership>(buildMembership(roleName: 'SALES_MANAGER')),
      );

      final afterPromotion = await service.hasPermission(
        organizationId: 'org-1',
        userId: 'user-1',
        capability: Capability.orderApprove,
      );
      expect((afterPromotion as AppSuccess<bool>).value, isTrue);
    });
  });
}
