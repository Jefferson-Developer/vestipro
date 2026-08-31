import '../../../utils/utils.dart';
import '../entities/conflict_audit_entry.dart';

/// Domain contract for the local, append-only conflict resolution audit
/// trail (TASK-110, EPIC-14 — seção 5.5 de `tasks.md`: "toda resolução deve
/// ser auditável").
///
/// [ConflictResolutionService] is the only writer of [record] — called
/// exactly once per `resolve` call, regardless of outcome. No method here
/// ever updates or deletes an entry: like the centralized `AuditLogEntry`
/// (`lib/features/audit_log/`), a conflict resolution decision, once
/// recorded, is permanent history.
abstract interface class ConflictAuditLogRepository {
  Future<AppResult<ConflictAuditEntry>> record(ConflictAuditEntry entry);

  /// Every audit entry for [organizationId], most recent first — used by a
  /// future review screen (e.g. TASK-112's Central de Sincronização) and by
  /// this task's own tests to assert every resolution left a traceable
  /// entry.
  Future<AppResult<List<ConflictAuditEntry>>> listByOrganization({
    required String organizationId,
  });
}
