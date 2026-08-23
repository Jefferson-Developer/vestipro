import '../../../../core/utils/utils.dart';
import '../entities/audit_log_entry.dart';
import '../entities/audit_log_entry_page.dart';
import '../value_objects/audit_action.dart';

/// Contract for the central, append-only administrative audit log
/// (`tasks.md`, seções 13 e 20; TASK-033).
///
/// Deliberately exposes no `update`/`delete` method: once written, an
/// [AuditLogEntry] can never be changed nor removed by the app — Firestore
/// Security Rules enforce the same invariant server-side, independent of
/// this contract, for every role including `OWNER`.
abstract interface class AuditLogRepository {
  /// Persists [entry] as a brand-new, immutable audit log entry scoped to
  /// [AuditLogEntry.organizationId]. [entry] must already carry a stable
  /// [AuditLogEntry.id] and [AuditLogEntry.timestamp] — see
  /// `RecordAuditLogUseCase`, the only caller expected to build one.
  Future<AppResult<AuditLogEntry>> record(AuditLogEntry entry);

  /// Lists [organizationId]'s audit log, newest first, respecting RBAC
  /// (only callers with [Capability.auditLogView] may see any result —
  /// enforced by `ListAuditLogEntriesUseCase`/Firestore Security Rules, not
  /// by this method itself).
  ///
  /// [before] pages backwards through the log without leaking any
  /// Firestore-specific cursor type into `domain/`: pass the
  /// [AuditLogEntry.timestamp] of the last entry of the previous page to
  /// fetch the next (strictly older) one. [from]/[to] narrow the result to
  /// a period; [action] narrows it to one [AuditAction].
  Future<AppResult<List<AuditLogEntry>>> listByOrganization({
    required String organizationId,
    int limit = 50,
    DateTime? before,
    DateTime? from,
    DateTime? to,
    AuditAction? action,
    String? actorUserId,
  });

  /// Cursor-paginated variant used by administrative UI: returns the current
  /// page plus [AuditLogEntryPage.hasMore]/[AuditLogEntryPage.nextCursor],
  /// supports a server-side actor filter and can group equivalent action
  /// codes (e.g. legacy `role.changed` plus current `user.roleUpdated`).
  Future<AppResult<AuditLogEntryPage>> listPageByOrganization({
    required String organizationId,
    int limit = 50,
    DateTime? before,
    DateTime? from,
    DateTime? to,
    Set<AuditAction> actions = const <AuditAction>{},
    String? actorUserId,
  });
}
