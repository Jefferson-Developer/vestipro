/// Reactive count of Outbox rows per non-terminal status for one tenant
/// scope (TASK-108, EPIC-14) — what [OutboxWatcherCubit] exposes for the
/// Central de Sincronização (TASK-112) to show pending/failed work in real
/// time, without ever loading every row just to count them.
final class OutboxSummary {
  const OutboxSummary({
    this.pendingCount = 0,
    this.syncingCount = 0,
    this.failedCount = 0,
    this.conflictCount = 0,
  });

  final int pendingCount;
  final int syncingCount;
  final int failedCount;
  final int conflictCount;

  /// Every operation that has not yet reached a terminal `synced` state.
  int get totalUnsyncedCount =>
      pendingCount + syncingCount + failedCount + conflictCount;

  /// Whether there is at least one operation that needs the user's
  /// attention (as opposed to simply waiting to sync).
  bool get hasFailuresOrConflicts => failedCount > 0 || conflictCount > 0;
}
