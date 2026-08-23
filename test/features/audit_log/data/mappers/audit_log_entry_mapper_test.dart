import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/audit_log/audit_log.dart';
import 'package:vestipro/features/audit_log/data/dtos/audit_log_entry_dto.dart';
import 'package:vestipro/features/audit_log/data/mappers/audit_log_entry_mapper.dart';

void main() {
  group('AuditLogEntryMapper', () {
    const mapper = AuditLogEntryMapper();
    final timestamp = DateTime.utc(2026, 1, 1);

    final dto = AuditLogEntryDto(
      id: 'log-1',
      organizationId: 'org-1',
      actorUserId: 'user-1',
      actorName: 'Ana Souza',
      action: 'role.changed',
      entityType: 'membership',
      entityId: 'user-2',
      previousValue: <String, dynamic>{'roleId': 'SALES_REP'},
      newValue: <String, dynamic>{'roleId': 'SALES_MANAGER'},
      timestamp: timestamp,
    );

    test('toEntity converts every field, including the parsed action', () {
      final entity = mapper.toEntity(dto);

      expect(entity.id, 'log-1');
      expect(entity.organizationId, 'org-1');
      expect(entity.actorUserId, 'user-1');
      expect(entity.actorName, 'Ana Souza');
      expect(entity.action, AuditAction.roleChanged);
      expect(entity.entityType, 'membership');
      expect(entity.entityId, 'user-2');
      expect(entity.previousValue, <String, dynamic>{'roleId': 'SALES_REP'});
      expect(entity.newValue, <String, dynamic>{'roleId': 'SALES_MANAGER'});
      expect(entity.timestamp, timestamp);
    });

    test('toDto is the exact inverse of toEntity', () {
      final entity = mapper.toEntity(dto);
      final roundTripped = mapper.toDto(entity);

      expect(roundTripped.id, dto.id);
      expect(roundTripped.organizationId, dto.organizationId);
      expect(roundTripped.action, dto.action);
      expect(roundTripped.previousValue, dto.previousValue);
      expect(roundTripped.newValue, dto.newValue);
    });

    test('actionToEntity resolves every AuditAction from its stored code', () {
      for (final action in AuditAction.values) {
        expect(mapper.actionToEntity(action.code), action);
      }
    });

    test('actionToEntity throws ValidationException for an unknown code', () {
      expect(
        () => mapper.actionToEntity('unknown.action'),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
