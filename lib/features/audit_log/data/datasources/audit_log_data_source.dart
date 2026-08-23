import '../dtos/audit_log_entry_dto.dart';
import '../dtos/audit_log_entry_page_dto.dart';

/// Data access contract for
/// `organizations/{organizationId}/auditLogs/{id}` documents (TASK-033).
/// [FirestoreAuditLogDataSource] is the only implementation today.
///
/// Deliberately exposes no `update`/`delete` method — an audit log entry,
/// once recorded, is never mutated nor removed by the app.
abstract interface class AuditLogDataSource {
  Future<AuditLogEntryDto> record(AuditLogEntryDto dto);

  /// Lists one cursor page of [organizationId]'s audit log, newest first.
  /// [before]/[from]/[to] filter on `timestamp`; [actionCodes] filters on
  /// `action` and [actorUserId] filters on the acting user. Never queries
  /// across organizations.
  Future<AuditLogEntryPageDto> listPageByOrganization({
    required String organizationId,
    int limit = 50,
    DateTime? before,
    DateTime? from,
    DateTime? to,
    Set<String> actionCodes = const <String>{},
    String? actorUserId,
  });
}
