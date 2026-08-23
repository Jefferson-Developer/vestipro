import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/audit_log/data/dtos/audit_log_entry_dto.dart';

void main() {
  group('AuditLogEntryDto', () {
    final json = <String, dynamic>{
      'organizationId': 'org-1',
      'actorUserId': 'user-1',
      'actorName': 'Ana Souza',
      'action': 'role.changed',
      'entityType': 'membership',
      'entityId': 'user-2',
      'previousValue': <String, dynamic>{'roleId': 'SALES_REP'},
      'newValue': <String, dynamic>{'roleId': 'SALES_MANAGER'},
      'timestamp': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
    };

    test(
      'fromJson parses a full Firestore payload, id supplied out-of-band',
      () {
        final dto = AuditLogEntryDto.fromJson(json, id: 'log-1');

        expect(dto.id, 'log-1');
        expect(dto.organizationId, 'org-1');
        expect(dto.actorUserId, 'user-1');
        expect(dto.actorName, 'Ana Souza');
        expect(dto.action, 'role.changed');
        expect(dto.entityType, 'membership');
        expect(dto.entityId, 'user-2');
        expect(dto.previousValue, <String, dynamic>{'roleId': 'SALES_REP'});
        expect(dto.newValue, <String, dynamic>{'roleId': 'SALES_MANAGER'});
        expect(dto.timestamp.toUtc(), DateTime.utc(2026, 1, 1));
      },
    );

    test(
      'fromJson parses a payload without previousValue/newValue (both null)',
      () {
        final minimalJson = Map<String, dynamic>.of(json)
          ..remove('previousValue')
          ..remove('newValue');

        final dto = AuditLogEntryDto.fromJson(minimalJson, id: 'log-1');

        expect(dto.previousValue, isNull);
        expect(dto.newValue, isNull);
      },
    );

    test('toJson never includes id as one of its keys', () {
      final dto = AuditLogEntryDto.fromJson(json, id: 'log-1');

      expect(dto.toJson().containsKey('id'), isFalse);
      expect(dto.toJson()['organizationId'], 'org-1');
      expect(dto.toJson()['action'], 'role.changed');
    });

    test(
      'fromJson throws ValidationException for a missing organizationId',
      () {
        final invalidJson = Map<String, dynamic>.of(json)
          ..remove('organizationId');

        expect(
          () => AuditLogEntryDto.fromJson(invalidJson, id: 'log-1'),
          throwsA(isA<ValidationException>()),
        );
      },
    );

    test(
      'fromJson throws ValidationException for a non-Timestamp timestamp',
      () {
        final invalidJson = Map<String, dynamic>.of(json)
          ..['timestamp'] = '2026-01-01';

        expect(
          () => AuditLogEntryDto.fromJson(invalidJson, id: 'log-1'),
          throwsA(isA<ValidationException>()),
        );
      },
    );

    test(
      'fromJson throws ValidationException when previousValue is not a Map',
      () {
        final invalidJson = Map<String, dynamic>.of(json)
          ..['previousValue'] = 'not-a-map';

        expect(
          () => AuditLogEntryDto.fromJson(invalidJson, id: 'log-1'),
          throwsA(isA<ValidationException>()),
        );
      },
    );
  });
}
