import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/organizations/organizations.dart';

void main() {
  group('Membership', () {
    final createdAt = DateTime.utc(2026, 1, 1);
    final updatedAt = DateTime.utc(2026, 1, 2);

    Membership buildMembership({
      String id = 'user-1',
      String organizationId = 'org-1',
      String userId = 'user-1',
      MembershipStatus status = MembershipStatus.active,
    }) {
      return Membership(
        id: id,
        organizationId: organizationId,
        userId: userId,
        roleId: 'SALES_REP',
        roleName: 'SALES_REP',
        status: status,
        version: 1,
        createdAt: createdAt,
        createdBy: 'user-1',
        updatedAt: updatedAt,
        updatedBy: 'user-1',
      );
    }

    test('two memberships with the same field values are equal', () {
      expect(buildMembership(), buildMembership());
    });

    test('memberships of different users are not equal even under the same '
        'organization', () {
      expect(
        buildMembership(id: 'user-1', userId: 'user-1'),
        isNot(buildMembership(id: 'user-2', userId: 'user-2')),
      );
    });

    test('memberships from different organizations are not equal even with '
        'the same userId', () {
      expect(
        buildMembership(organizationId: 'org-1'),
        isNot(buildMembership(organizationId: 'org-2')),
      );
    });

    test(
      'id always mirrors userId (organizations/{orgId}/members/{userId})',
      () {
        final membership = buildMembership(id: 'user-42', userId: 'user-42');
        expect(membership.id, membership.userId);
      },
    );

    test('teamIds defaults to an empty list', () {
      expect(buildMembership().teamIds, isEmpty);
    });

    test('copyWith changes roleId/roleName without mutating organizationId '
        'or userId', () {
      final original = buildMembership();
      final copy = original.copyWith(
        roleId: 'SALES_MANAGER',
        roleName: 'SALES_MANAGER',
      );

      expect(original.organizationId, 'org-1');
      expect(original.userId, 'user-1');
      expect(original.roleId, 'SALES_REP');
      expect(copy.organizationId, 'org-1');
      expect(copy.userId, 'user-1');
      expect(copy.roleId, 'SALES_MANAGER');
      expect(original, isNot(copy));
    });

    test('deletedAt is null by default (membership not soft-deleted)', () {
      expect(buildMembership().deletedAt, isNull);
    });

    test('status distinguishes active from inactive memberships', () {
      expect(
        buildMembership(status: MembershipStatus.active),
        isNot(buildMembership(status: MembershipStatus.inactive)),
      );
    });
  });
}
