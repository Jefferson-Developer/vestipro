/// One side (local or remote) of a detected conflict — a flat, already
/// decoded view of an entity's fields at a point in time, plus the metadata
/// [ConflictResolutionService] needs to decide/explain a resolution
/// (TASK-110, EPIC-14).
///
/// [data] is expected to be a flat map of business fields (never nested
/// arbitrarily deep) so field-level comparison
/// (`ConflictFieldMerge`/divergence detection) can work key by key without
/// its own recursive-diff logic.
final class ConflictSnapshot {
  const ConflictSnapshot({
    required this.data,
    required this.updatedAt,
    this.version,
  });

  /// Flat snapshot of the entity's business fields.
  final Map<String, Object?> data;

  /// Last-write timestamp for this side — the fallback ordering signal for
  /// [ConflictPolicy.lastWriteWins] when [version] is unavailable/equal on
  /// both sides.
  final DateTime updatedAt;

  /// Optional monotonically increasing version counter for this side, when
  /// the entity tracks one (`tasks.md`, seção 5.3: toda entidade
  /// sincronizável carrega `version`) — preferred over [updatedAt] for
  /// ordering when present on both sides, since wall-clock timestamps can
  /// collide or skew across devices.
  final int? version;
}
