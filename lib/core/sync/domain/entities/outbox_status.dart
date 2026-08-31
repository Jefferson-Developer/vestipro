/// State machine of an Outbox operation (TASK-108, EPIC-14 — seção 5.4 de
/// `tasks.md`).
///
/// Transitions today: `pending -> syncing -> synced`,
/// `pending -> syncing -> failed -> syncing` (retry, TASK-109) and
/// `pending -> syncing -> conflict` (manual resolution, TASK-110/TASK-112).
/// A row is never deleted on failure — only a confirmed `synced` (or an
/// explicit resolution out of `conflict`) is expected to eventually retire
/// it, so an offline operation can never be silently lost.
enum OutboxStatus { pending, syncing, synced, failed, conflict }

extension OutboxStatusCode on OutboxStatus {
  /// Stable identifier persisted in `OutboxTable.status` — never the enum
  /// index, same convention as [OutboxStatus]'s siblings.
  String get code {
    return switch (this) {
      OutboxStatus.pending => 'pending',
      OutboxStatus.syncing => 'syncing',
      OutboxStatus.synced => 'synced',
      OutboxStatus.failed => 'failed',
      OutboxStatus.conflict => 'conflict',
    };
  }

  static OutboxStatus? fromCode(String code) {
    for (final status in OutboxStatus.values) {
      if (status.code == code) {
        return status;
      }
    }
    return null;
  }
}
