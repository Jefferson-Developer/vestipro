import 'audit_log_entry.dart';

/// One cursor-paginated slice of the administrative audit log.
///
/// The cursor is the timestamp of the last entry in [entries], matching the
/// repository contract and keeping Firestore snapshot types out of domain/UI.
final class AuditLogEntryPage {
  const AuditLogEntryPage({
    required this.entries,
    required this.hasMore,
    this.nextCursor,
  });

  final List<AuditLogEntry> entries;
  final bool hasMore;
  final DateTime? nextCursor;
}
