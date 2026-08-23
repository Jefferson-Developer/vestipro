import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../domain/entities/audit_log_entry.dart';
import '../../domain/value_objects/audit_action.dart';
import '../dtos/audit_log_entry_dto.dart';

@lazySingleton
final class AuditLogEntryMapper {
  const AuditLogEntryMapper();

  AuditLogEntry toEntity(AuditLogEntryDto dto) {
    return AuditLogEntry(
      id: dto.id,
      organizationId: dto.organizationId,
      actorUserId: dto.actorUserId,
      actorName: dto.actorName,
      action: actionToEntity(dto.action),
      entityType: dto.entityType,
      entityId: dto.entityId,
      previousValue: dto.previousValue,
      newValue: dto.newValue,
      timestamp: dto.timestamp,
    );
  }

  AuditLogEntryDto toDto(AuditLogEntry entity) {
    return AuditLogEntryDto(
      id: entity.id,
      organizationId: entity.organizationId,
      actorUserId: entity.actorUserId,
      actorName: entity.actorName,
      action: actionToDto(entity.action),
      entityType: entity.entityType,
      entityId: entity.entityId,
      previousValue: entity.previousValue,
      newValue: entity.newValue,
      timestamp: entity.timestamp,
    );
  }

  AuditAction actionToEntity(String value) {
    for (final action in AuditAction.values) {
      if (action.code == value) return action;
    }
    throw ValidationException(
      'Invalid audit action.',
      code: 'invalid_audit_action',
      cause: value,
    );
  }

  String actionToDto(AuditAction action) => action.code;
}
