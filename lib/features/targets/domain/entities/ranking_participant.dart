/// One candidate peer fed into `RankingCalculationService.compute`
/// (TASK-118, EPIC-15), already resolved by `RankingDashboardCubit` from the
/// exact same source TASK-116's dashboard uses
/// (`TargetRepository.listByDimension` +
/// `TargetAchievementRepository.getForTarget`'s `achievedValueCache`) — never
/// a client-side sum of raw order documents.
///
/// This is deliberately a plain data holder, never itself computing
/// anything: [RankingCalculationService] is the single place achievement %,
/// sort order and RBAC redaction happen, exactly like
/// `TargetProgressViewModel.compute` is the single place gap/atingimento/
/// projeção are computed for the achievement dashboard.
final class RankingParticipant {
  const RankingParticipant({
    required this.dimensionId,
    required this.displayName,
    required this.targetValue,
    this.realizedValue,
  });

  /// The `Target.dimensionId` this participant represents.
  final String dimensionId;

  final String displayName;

  final double targetValue;

  /// The server-computed realized value for the compared period, or `null`
  /// when no aggregation has calculated it yet
  /// (`TargetAchievementSnapshot.isCalculated == false`) — this participant
  /// is excluded from both ranking and `RankingBoard.totalParticipants`
  /// until a value exists (see that field's own doc).
  final double? realizedValue;

  bool get isCalculated => realizedValue != null;
}
