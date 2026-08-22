import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/organizations/organizations.dart';

void main() {
  group('Team', () {
    final createdAt = DateTime.utc(2026, 1, 1);
    final updatedAt = DateTime.utc(2026, 1, 2);

    Team buildTeam({
      String id = 'team-1',
      String organizationId = 'org-1',
      List<String> memberIds = const <String>[],
    }) {
      return Team(
        id: id,
        organizationId: organizationId,
        name: 'Equipe Blumenau',
        memberIds: memberIds,
        version: 1,
        createdAt: createdAt,
        createdBy: 'user-1',
        updatedAt: updatedAt,
        updatedBy: 'user-1',
      );
    }

    test('two teams with the same field values are equal', () {
      expect(buildTeam(), buildTeam());
    });

    test('teams with different ids are not equal', () {
      expect(buildTeam(id: 'team-1'), isNot(buildTeam(id: 'team-2')));
    });

    test('teams from different organizations are not equal even with the '
        'same id', () {
      expect(
        buildTeam(organizationId: 'org-1'),
        isNot(buildTeam(organizationId: 'org-2')),
      );
    });

    test('memberIds defaults to an empty list', () {
      expect(buildTeam().memberIds, isEmpty);
    });

    test('copyWith produces a new instance without mutating the original '
        'organizationId', () {
      final original = buildTeam(memberIds: <String>['user-1']);
      final copy = original.copyWith(memberIds: <String>['user-1', 'user-2']);

      expect(original.organizationId, 'org-1');
      expect(original.memberIds, <String>['user-1']);
      expect(copy.organizationId, 'org-1');
      expect(copy.memberIds, <String>['user-1', 'user-2']);
      expect(original, isNot(copy));
    });

    test('deletedAt is null by default (team not soft-deleted)', () {
      expect(buildTeam().deletedAt, isNull);
    });
  });
}
