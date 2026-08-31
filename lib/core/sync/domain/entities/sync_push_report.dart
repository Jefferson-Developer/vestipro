/// Metrics of one `SyncEngine.runPush` call (TASK-109, EPIC-14 — seção 14 de
/// `tasks.md`, "métricas de sincronização") — logged through
/// [AnalyticsEvents.syncPushCompleted] and the extension point the future
/// Central de Sincronização (TASK-112) surfaces to the user.
final class SyncPushReport {
  const SyncPushReport({
    required this.attempted,
    required this.synced,
    required this.failed,
    required this.conflicts,
    required this.duration,
  });

  /// Operations this cycle actually tried to push (excludes rows still
  /// waiting for their backoff window, and rows that already exhausted
  /// their retry budget).
  final int attempted;

  final int synced;
  final int failed;
  final int conflicts;
  final Duration duration;
}
