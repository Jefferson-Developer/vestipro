import '../value_objects/ranking_dimension_type.dart';

/// The concrete set of peer `Target.dimensionId`s a caller may be compared
/// against in a ranking comercial (TASK-118, EPIC-15) — resolved by
/// `RankingPeerResolverService`, never by the UI.
///
/// This is a distinct concern from `TargetVisibilityFilter`
/// (TASK-116): that filter answers "may I *query* this one dimension's
/// `Target`", while [RankingPeerScope] answers "who are *all* the peers I
/// should be compared against" — a question the achievement dashboard never
/// needed to ask (it only ever shows one dimension at a time).
final class RankingPeerScope {
  const RankingPeerScope({required this.dimensionType, required this.peerIds});

  final RankingDimensionType dimensionType;

  /// Every `Target.dimensionId` the caller may be compared against,
  /// including the caller's own when [dimensionType] is
  /// [RankingDimensionType.salesRep] — an empty set means "no ranking to
  /// show" (e.g. a SALES_REP in no Team yet).
  final Set<String> peerIds;

  bool get isEmpty => peerIds.isEmpty;
}
