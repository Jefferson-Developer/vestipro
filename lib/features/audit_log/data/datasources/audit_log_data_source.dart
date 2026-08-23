import '../dtos/audit_log_entry_dto.dart';

/// Data access contract for
/// `organizations/{organizationId}/auditLogs/{id}` documents (TASK-033).
/// [FirestoreAuditLogDataSource] is the only implementation today.
///
/// Deliberately exposes no `update`/`delete` method — an audit log entry,
/// once recorded, is never mutated nor removed by the app.
abstract interface class AuditLogDataSource {
  Future<AuditLogEntryDto> record(AuditLogEntryDto dto);

  /// Lists [organizationId]'s audit log, newest first. [before]/[from]/[to]
  /// filter on `timestamp`; [actionCode] filters on `action`
  /// ([AuditActionCode.code]). Never queries across organizations.
  Future<List<AuditLogEntryDto>> listByOrganization({
    required String organizationId,
    int limit = 50,
    DateTime? before,
    DateTime? from,
    DateTime? to,
    String? actionCode,
  });
}
