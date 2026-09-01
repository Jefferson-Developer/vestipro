/// A server-computed "quanto já foi realizado" snapshot for one `Target`
/// (TASK-116, EPIC-15): [realizedValue] is a value already aggregated
/// server-side (a Cloud Function/BI pipeline reading faturados/aprovados
/// orders — never a value this app computes by summing raw documents on the
/// client, per the BI aggregation rule in `AGENTS.md`) and cached locally in
/// `TargetsTable.achievedValueCache`, which `TargetsTable`'s own docs already
/// reserve for this exact dashboard.
///
/// [realizedValue] and [calculatedAt] are always both `null` or both
/// non-null: `null` means "no aggregation pipeline has populated this
/// Target's cache yet" — a real, expected state today, since no task before
/// TASK-116 wires that pipeline (`SharedPreferencesTargetRepository`'s own
/// docs note the Firestore/Outbox wiring for `Target` itself is still
/// pending) — never "realized zero". [TargetDashboardCubit] must render its
/// own "cálculo ainda não disponível" state for that case, never silently
/// treat a `null` as zero achievement.
final class TargetAchievementSnapshot {
  const TargetAchievementSnapshot({
    required this.targetId,
    this.realizedValue,
    this.calculatedAt,
  }) : assert(
         (realizedValue == null) == (calculatedAt == null),
         'realizedValue and calculatedAt must both be null or both be set.',
       );

  final String targetId;

  /// The last server-computed realized value for [targetId], or `null` when
  /// no aggregation has run yet.
  final double? realizedValue;

  /// When [realizedValue] was computed server-side, or `null` alongside it.
  final DateTime? calculatedAt;

  bool get isCalculated => realizedValue != null;
}
