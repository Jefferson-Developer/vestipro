import 'package:uuid/uuid.dart';

import 'entities/audit_log_entry.dart';
import 'value_objects/audit_action.dart';

/// Keys that must never reach `AuditLogEntry.previousValue`/`newValue`
/// (`tasks.md`, seção 13: "dados sensíveis nunca devem ser armazenados no
/// log"), matched case-insensitively so `password`, `Password` and
/// `PASSWORD` are all stripped the same way.
const Set<String> sensitiveAuditValueKeys = <String>{
  'password',
  'senha',
  'token',
  'secret',
  'apikey',
  'api_key',
  'creditcard',
  'credit_card',
  'cpf',
  'cnpj',
};

/// Builds a well-formed, sanitized [AuditLogEntry] — the single place that
/// decides its [AuditLogEntry.id]/[AuditLogEntry.timestamp] and strips
/// [sensitiveAuditValueKeys] from [previousValue]/[newValue] (`tasks.md`,
/// seção 13; TASK-033).
///
/// Kept as a pure, stateless factory (not `@injectable`) instead of a
/// method on `RecordAuditLogUseCase` so any use case that already needs to
/// depend on [AuditLogRepository] directly (e.g. `AssignRoleToUserUseCase`)
/// can build the exact same well-formed entry without also depending on
/// `RecordAuditLogUseCase` itself — a `final class` use case, which
/// mocktail cannot `implements` from a different library/test file.
abstract final class AuditLogEntryFactory {
  static AuditLogEntry build({
    required String organizationId,
    required String actorUserId,
    required String actorName,
    required AuditAction action,
    required String entityType,
    required String entityId,
    Map<String, Object?>? previousValue,
    Map<String, Object?>? newValue,
    Uuid uuid = const Uuid(),
    DateTime? timestamp,
  }) {
    return AuditLogEntry(
      id: uuid.v4(),
      organizationId: organizationId,
      actorUserId: actorUserId,
      actorName: actorName,
      action: action,
      entityType: entityType,
      entityId: entityId,
      previousValue: sanitizeAuditValue(previousValue),
      newValue: sanitizeAuditValue(newValue),
      timestamp: (timestamp ?? DateTime.now()).toUtc(),
    );
  }

  /// Strips any key in [sensitiveAuditValueKeys] from [value]
  /// (case-insensitive, one level deep — [previousValue]/[newValue] are
  /// expected to be flat snapshots of entity fields, never arbitrary nested
  /// payloads). Returns `null` unchanged, and never mutates the map passed
  /// in.
  static Map<String, Object?>? sanitizeAuditValue(Map<String, Object?>? value) {
    if (value == null) return null;

    final sanitized = <String, Object?>{};
    for (final entry in value.entries) {
      if (sensitiveAuditValueKeys.contains(entry.key.toLowerCase())) {
        continue;
      }
      sanitized[entry.key] = entry.value;
    }
    return sanitized;
  }
}
