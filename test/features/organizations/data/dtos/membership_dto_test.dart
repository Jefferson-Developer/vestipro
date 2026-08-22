import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/organizations/data/dtos/membership_dto.dart';

void main() {
  group('MembershipDto', () {
    final json = <String, dynamic>{
      'organizationId': 'org-1',
      'userId': 'user-1',
      'roleId': 'SALES_REP',
      'roleName': 'SALES_REP',
      'teamIds': <String>['team-1'],
      'status': 'active',
      'version': 1,
      'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      'createdBy': 'user-1',
      'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      'updatedBy': 'user-1',
    };

    test(
      'fromJson parses a full Firestore payload, id supplied out-of-band',
      () {
        final dto = MembershipDto.fromJson(json, id: 'user-1');

        expect(dto.id, 'user-1');
        expect(dto.organizationId, 'org-1');
        expect(dto.userId, 'user-1');
        expect(dto.roleId, 'SALES_REP');
        expect(dto.teamIds, <String>['team-1']);
        expect(dto.status, 'active');
      },
    );

    test('fromJson parses a payload without teamIds (defaults to empty)', () {
      final minimalJson = Map<String, dynamic>.of(json)..remove('teamIds');

      final dto = MembershipDto.fromJson(minimalJson, id: 'user-1');

      expect(dto.teamIds, isEmpty);
    });

    test('toJson never includes id as one of its keys', () {
      final dto = MembershipDto.fromJson(json, id: 'user-1');

      expect(dto.toJson().containsKey('id'), isFalse);
      expect(dto.toJson()['userId'], 'user-1');
    });

    test('fromJson throws ValidationException for a missing roleId', () {
      final invalidJson = Map<String, dynamic>.of(json)..remove('roleId');

      expect(
        () => MembershipDto.fromJson(invalidJson, id: 'user-1'),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
