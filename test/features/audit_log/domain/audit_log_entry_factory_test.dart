import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/audit_log/audit_log.dart';
import 'package:vestipro/features/audit_log/domain/audit_log_entry_factory.dart';

void main() {
  group('AuditLogEntryFactory.build', () {
    test('builds an entry with a generated id and a UTC timestamp', () {
      final entry = AuditLogEntryFactory.build(
        organizationId: 'org-1',
        actorUserId: 'user-1',
        actorName: 'Ana Souza',
        action: AuditAction.roleChanged,
        entityType: 'membership',
        entityId: 'user-2',
      );

      expect(entry.id, isNotEmpty);
      expect(entry.organizationId, 'org-1');
      expect(entry.actorUserId, 'user-1');
      expect(entry.actorName, 'Ana Souza');
      expect(entry.action, AuditAction.roleChanged);
      expect(entry.entityType, 'membership');
      expect(entry.entityId, 'user-2');
      expect(entry.timestamp.isUtc, isTrue);
    });

    test('uses the injected timestamp when given (test seam), converted to '
        'UTC', () {
      final entry = AuditLogEntryFactory.build(
        organizationId: 'org-1',
        actorUserId: 'user-1',
        actorName: 'Ana Souza',
        action: AuditAction.roleChanged,
        entityType: 'membership',
        entityId: 'user-2',
        timestamp: DateTime.utc(2026, 1, 1),
      );

      expect(entry.timestamp, DateTime.utc(2026, 1, 1));
    });

    test('strips sensitive keys (password, token, secret, ...) from '
        'previousValue and newValue, case-insensitively', () {
      final entry = AuditLogEntryFactory.build(
        organizationId: 'org-1',
        actorUserId: 'user-1',
        actorName: 'Ana Souza',
        action: AuditAction.roleChanged,
        entityType: 'membership',
        entityId: 'user-2',
        previousValue: <String, Object?>{
          'roleId': 'SALES_REP',
          'Password': 'super-secret',
        },
        newValue: <String, Object?>{
          'roleId': 'SALES_MANAGER',
          'TOKEN': 'abc123',
          'secret': 'shh',
        },
      );

      expect(entry.previousValue, <String, Object?>{'roleId': 'SALES_REP'});
      expect(entry.newValue, <String, Object?>{'roleId': 'SALES_MANAGER'});
    });

    test('keeps previousValue/newValue null when none is given', () {
      final entry = AuditLogEntryFactory.build(
        organizationId: 'org-1',
        actorUserId: 'user-1',
        actorName: 'Ana Souza',
        action: AuditAction.roleChanged,
        entityType: 'membership',
        entityId: 'user-2',
      );

      expect(entry.previousValue, isNull);
      expect(entry.newValue, isNull);
    });

    test('never mutates the map passed in as previousValue/newValue', () {
      final original = <String, Object?>{
        'roleId': 'SALES_REP',
        'password': 'super-secret',
      };

      AuditLogEntryFactory.build(
        organizationId: 'org-1',
        actorUserId: 'user-1',
        actorName: 'Ana Souza',
        action: AuditAction.roleChanged,
        entityType: 'membership',
        entityId: 'user-2',
        previousValue: original,
      );

      expect(original, <String, Object?>{
        'roleId': 'SALES_REP',
        'password': 'super-secret',
      });
    });
  });
}
