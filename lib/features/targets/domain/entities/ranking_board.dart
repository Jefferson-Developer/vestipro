import '../value_objects/ranking_access_level.dart';
import 'ranking_entry.dart';

/// The result of `RankingCalculationService.compute` (TASK-118, EPIC-15):
/// already redacted for [accessLevel] — `RankingDashboardPage` never has to
/// decide what to hide, it only ever renders [entries] as given.
final class RankingBoard {
  const RankingBoard({
    required this.accessLevel,
    required this.entries,
    required this.totalParticipants,
    this.currentUserRank,
  });

  final RankingAccessLevel accessLevel;

  /// The rows the caller may actually see, already sorted by rank.
  ///
  /// When [accessLevel] is [RankingAccessLevel.full], this is every ranked
  /// peer. When [accessLevel] is [RankingAccessLevel.relativePositionOnly],
  /// this is *at most* one entry — the caller's own
  /// ([RankingEntry.isCurrentUser]) — and only when the caller themselves
  /// has a calculated achievement to rank; every other peer's name/value is
  /// never included here at all, not merely hidden by the UI.
  final List<RankingEntry> entries;

  /// How many peers were actually ranked (had a calculated achievement for
  /// the compared period) — always accurate regardless of [accessLevel],
  /// since revealing a count is not revealing anyone's identity or value.
  /// This is the "de 12" in "você está em 4º de 12".
  final int totalParticipants;

  /// The signed-in caller's 1-based position among [totalParticipants], or
  /// `null` when the caller has no calculated achievement for the compared
  /// period yet (so they cannot be ranked, even though peers may be).
  final int? currentUserRank;

  bool get isCurrentUserRanked => currentUserRank != null;

  bool get isEmpty => totalParticipants == 0;
}
