/// One row of a resolved ranking comercial (TASK-118, EPIC-15): the peer's
/// achievement for the compared period, already placed at [rank].
///
/// Never itself decides whether it should be visible to the current caller —
/// `RankingCalculationService.compute` only ever constructs the
/// [RankingEntry]s a given `RankingAccessLevel` is allowed to return in the
/// first place; there is no "hidden" flag here, an entry either exists in
/// `RankingBoard.entries` or it does not.
final class RankingEntry {
  const RankingEntry({
    required this.rank,
    required this.dimensionId,
    required this.displayName,
    required this.achievementPercentage,
    required this.realizedValue,
    required this.targetValue,
    required this.isCurrentUser,
  });

  /// 1-based position, assigned by [RankingBoard]'s deterministic sort/
  /// tie-break — never recomputed by the presentation layer.
  final int rank;

  /// The `Target.dimensionId` this entry represents (a user id when
  /// ranking `salesRep`, a `Team.id` when ranking `team`).
  final String dimensionId;

  final String displayName;

  /// `realizedValue / targetValue * 100`, same zero-target guard as
  /// `TargetProgressViewModel.achievementPercentage`.
  final double achievementPercentage;

  final double realizedValue;
  final double targetValue;

  /// Whether this entry is the signed-in caller's own — the "destaque da
  /// posição do usuário logado" the task asks for.
  final bool isCurrentUser;
}
