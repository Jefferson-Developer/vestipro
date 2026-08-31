/// Result of [ConflictFieldMerge.compute] — either a safe merge or the set
/// of fields that changed on both sides and must not be merged silently
/// (TASK-110, EPIC-14 — seção 5.5 de `tasks.md`).
final class ConflictFieldMergeResult {
  const ConflictFieldMergeResult._({
    required this.mergedData,
    required this.mergedFields,
    required this.conflictingFields,
  });

  /// `mergedData` combining [ConflictFieldMerge.compute]'s `remote` and
  /// `local` inputs, populated only when [conflictingFields] is empty.
  final Map<String, Object?> mergedData;

  /// Which fields in [mergedData] came from the local side — empty when
  /// [conflictingFields] is not.
  final Set<String> mergedFields;

  /// Fields that changed on both sides to different values relative to
  /// `base` — never merged automatically. Empty means the merge in
  /// [mergedData] is safe to apply.
  final Set<String> conflictingFields;

  bool get hasConflict => conflictingFields.isNotEmpty;
}

/// Pure, stateless field-by-field merge for [ConflictPolicy.fieldMerge]
/// entities (TASK-110, EPIC-14).
///
/// Kept as a standalone unit (not inlined in [ConflictResolutionService]) so
/// its merge/conflict-detection logic is directly unit-testable without any
/// persistence dependency, per this task's own required test: "alterações em
/// campos distintos combinadas corretamente; alteração no mesmo campo dos
/// dois lados gera conflito em vez de merge silencioso".
abstract final class ConflictFieldMerge {
  /// Computes a safe merge of `local` and `remote` relative to `base` (the
  /// last snapshot both sides are known to have agreed on before either
  /// edited it).
  ///
  /// A field is "changed" on a side when its value there differs from
  /// `base` (a field absent from `base` counts as `null` there). Two sides
  /// changing the *same* field to the *same* resulting value is not a
  /// conflict (there is nothing to reconcile); two sides changing the same
  /// field to *different* values is always reported in
  /// [ConflictFieldMergeResult.conflictingFields], never guessed.
  static ConflictFieldMergeResult compute({
    required Map<String, Object?> base,
    required Map<String, Object?> local,
    required Map<String, Object?> remote,
  }) {
    final allKeys = <String>{...base.keys, ...local.keys, ...remote.keys};

    final localChanged = <String>{};
    final remoteChanged = <String>{};
    for (final key in allKeys) {
      final baseValue = base[key];
      if (local[key] != baseValue) localChanged.add(key);
      if (remote[key] != baseValue) remoteChanged.add(key);
    }

    final conflicting = <String>{};
    for (final key in localChanged.intersection(remoteChanged)) {
      if (local[key] != remote[key]) conflicting.add(key);
    }

    if (conflicting.isNotEmpty) {
      return ConflictFieldMergeResult._(
        mergedData: const <String, Object?>{},
        mergedFields: const <String>{},
        conflictingFields: conflicting,
      );
    }

    // Safe to merge: start from remote (covers "unchanged by either" and
    // "changed only remotely"), then overlay every field changed only
    // locally so its edit is never lost.
    final merged = <String, Object?>{...remote};
    final mergedFromLocal = <String>{};
    for (final key in localChanged) {
      merged[key] = local[key];
      mergedFromLocal.add(key);
    }

    return ConflictFieldMergeResult._(
      mergedData: merged,
      mergedFields: mergedFromLocal,
      conflictingFields: const <String>{},
    );
  }
}
