import 'package:freezed_annotation/freezed_annotation.dart';

import '../value_objects/audit_action.dart';

part 'audit_log_entry.freezed.dart';

/// One immutable record in the central administrative audit log
/// (`tasks.md`, seções 13 e 20; TASK-033), stored at
/// `organizations/{organizationId}/auditLogs/{id}`.
///
/// Every field is set once, at creation — [AuditLogRepository] exposes no
/// `update`, and Firestore Security Rules deny `update`/`delete` for every
/// role, including `OWNER`. [actorName] is a snapshot of the acting user's
/// display name *at the time of the action*, kept alongside [actorUserId]
/// so the log stays readable even if that user is later renamed, deleted or
/// removed from the Organization. [previousValue]/[newValue] must never
/// carry secrets (passwords, tokens) or unnecessary personal data — callers
/// building one go through `RecordAuditLogUseCase`, which strips any known
/// sensitive key before this entity is ever created.
@freezed
abstract class AuditLogEntry with _$AuditLogEntry {
  const factory AuditLogEntry({
    required String id,
    required String organizationId,
    required String actorUserId,
    required String actorName,
    required AuditAction action,
    required String entityType,
    required String entityId,
    Map<String, Object?>? previousValue,
    Map<String, Object?>? newValue,
    required DateTime timestamp,
  }) = _AuditLogEntry;
}
