import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/audit_log/audit_log.dart';

void main() {
  group('AuditLogEntry', () {
    final timestamp = DateTime.utc(2026, 1, 1, 12);

    AuditLogEntry buildEntry({
      String id = 'log-1',
      String organizationId = 'org-1',
      AuditAction action = AuditAction.roleChanged,
      Map<String, Object?>? previousValue,
      Map<String, Object?>? newValue,
    }) {
      return AuditLogEntry(
        id: id,
        organizationId: organizationId,
        actorUserId: 'user-1',
        actorName: 'Ana Souza',
        action: action,
        entityType: 'membership',
        entityId: 'user-2',
        previousValue: previousValue,
        newValue: newValue,
        timestamp: timestamp,
      );
    }

    test('two entries with the same field values are equal', () {
      expect(buildEntry(), buildEntry());
    });

    test('entries from different organizations are not equal even with the '
        'same id', () {
      expect(
        buildEntry(organizationId: 'org-1'),
        isNot(buildEntry(organizationId: 'org-2')),
      );
    });

    test('entries with different actions are not equal', () {
      expect(
        buildEntry(action: AuditAction.roleChanged),
        isNot(buildEntry(action: AuditAction.userDeactivated)),
      );
    });

    test('previousValue/newValue default to null (nothing to compare, e.g. '
        'a brand-new Membership has no "previous" role)', () {
      final entry = buildEntry();
      expect(entry.previousValue, isNull);
      expect(entry.newValue, isNull);
    });

    test('previousValue/newValue are kept as given (sanitization is '
        'AuditLogEntryFactory/RecordAuditLogUseCase\'s job, not the '
        'entity\'s)', () {
      final entry = buildEntry(
        previousValue: <String, Object?>{'roleId': 'SALES_REP'},
        newValue: <String, Object?>{'roleId': 'SALES_MANAGER'},
      );

      expect(entry.previousValue, <String, Object?>{'roleId': 'SALES_REP'});
      expect(entry.newValue, <String, Object?>{'roleId': 'SALES_MANAGER'});
    });

    test('copyWith changes one field without mutating the original '
        'instance (immutability)', () {
      final original = buildEntry();
      final copy = original.copyWith(actorName: 'Outro Ator');

      expect(original.actorName, 'Ana Souza');
      expect(copy.actorName, 'Outro Ator');
      expect(original, isNot(copy));
    });
  });
}
