/// Metrics of one `SyncEngine.runPull` call (TASK-109, EPIC-14 — seção 14 de
/// `tasks.md`, "métricas de sincronização"), aggregated across every
/// registered `SyncPullSource`.
final class SyncPullReport {
  const SyncPullReport({
    required this.sourcesProcessed,
    required this.sourcesFailed,
    required this.applied,
    required this.skipped,
    required this.rejectedCrossTenant,
    required this.duration,
  });

  /// How many `SyncPullSource`s this cycle attempted to pull from.
  final int sourcesProcessed;

  /// How many of those sources returned a failure fetching at least one
  /// page — that source's cursor is left untouched, retried next cycle.
  final int sourcesFailed;

  /// Records applied to the local Drift store this cycle.
  final int applied;

  /// Records skipped because their entity has a pending/unsynced Outbox
  /// operation locally — never applied without going through TASK-110's
  /// conflict resolution first.
  final int skipped;

  /// Records rejected outright because their `organizationId` did not match
  /// the scope this pull was run for — see [SyncEngine.runPull]'s
  /// tenant-isolation guard. Should always be `0` in practice; a non-zero
  /// value means a `SyncPullSource`'s own remote query is not scoping by
  /// tenant the way it must.
  final int rejectedCrossTenant;

  final Duration duration;
}
