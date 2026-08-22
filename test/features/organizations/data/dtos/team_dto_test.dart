import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/organizations/data/dtos/team_dto.dart';

void main() {
  group('TeamDto', () {
    final json = <String, dynamic>{
      'organizationId': 'org-1',
      'name': 'Equipe Blumenau',
      'memberIds': <String>['user-1', 'user-2'],
      'version': 1,
      'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      'createdBy': 'user-1',
      'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      'updatedBy': 'user-1',
    };

    test(
      'fromJson parses a full Firestore payload, id supplied out-of-band',
      () {
        final dto = TeamDto.fromJson(json, id: 'team-1');

        expect(dto.id, 'team-1');
        expect(dto.organizationId, 'org-1');
        expect(dto.memberIds, <String>['user-1', 'user-2']);
        expect(dto.version, 1);
      },
    );

    test('fromJson parses a payload without memberIds (defaults to empty)', () {
      final minimalJson = Map<String, dynamic>.of(json)..remove('memberIds');

      final dto = TeamDto.fromJson(minimalJson, id: 'team-1');

      expect(dto.memberIds, isEmpty);
    });

    test('toJson never includes id as one of its keys', () {
      final dto = TeamDto.fromJson(json, id: 'team-1');

      expect(dto.toJson().containsKey('id'), isFalse);
      expect(dto.toJson()['memberIds'], <String>['user-1', 'user-2']);
    });

    test(
      'fromJson throws ValidationException for a missing organizationId',
      () {
        final invalidJson = Map<String, dynamic>.of(json)
          ..remove('organizationId');

        expect(
          () => TeamDto.fromJson(invalidJson, id: 'team-1'),
          throwsA(isA<ValidationException>()),
        );
      },
    );
  });
}
