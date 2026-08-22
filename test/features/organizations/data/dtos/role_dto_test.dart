import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/organizations/data/dtos/role_dto.dart';

void main() {
  group('RoleDto', () {
    final json = <String, dynamic>{
      'organizationId': 'org-1',
      'name': 'OWNER',
      'isSystemRole': true,
      'version': 1,
      'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      'createdBy': 'user-1',
      'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      'updatedBy': 'user-1',
    };

    test(
      'fromJson parses a full Firestore payload, id supplied out-of-band',
      () {
        final dto = RoleDto.fromJson(json, id: 'OWNER');

        expect(dto.id, 'OWNER');
        expect(dto.organizationId, 'org-1');
        expect(dto.name, 'OWNER');
        expect(dto.isSystemRole, isTrue);
        expect(dto.version, 1);
      },
    );

    test('toJson never includes id as one of its keys', () {
      final dto = RoleDto.fromJson(json, id: 'OWNER');

      expect(dto.toJson().containsKey('id'), isFalse);
      expect(dto.toJson()['organizationId'], 'org-1');
      expect(dto.toJson()['isSystemRole'], isTrue);
    });

    test(
      'fromJson throws ValidationException for a missing organizationId',
      () {
        final invalidJson = Map<String, dynamic>.of(json)
          ..remove('organizationId');

        expect(
          () => RoleDto.fromJson(invalidJson, id: 'OWNER'),
          throwsA(isA<ValidationException>()),
        );
      },
    );

    test('fromJson throws ValidationException for a non-bool isSystemRole', () {
      final invalidJson = Map<String, dynamic>.of(json)
        ..['isSystemRole'] = 'true';

      expect(
        () => RoleDto.fromJson(invalidJson, id: 'OWNER'),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
