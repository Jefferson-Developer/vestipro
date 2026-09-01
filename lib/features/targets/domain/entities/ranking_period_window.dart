/// The `[start, end)` window a ranking comercial (TASK-118, EPIC-15) compares
/// peers within — deliberately decoupled from any single `Target`: unlike
/// the achievement dashboard (TASK-116), which always shows one dimension's
/// one `Target` at a time, a ranking compares *many* dimensions' `Target`s
/// that must all share the exact same period to be a fair comparison. This
/// is the shape `RankingDashboardCubit` groups every peer's candidate
/// `Target`s by before choosing which peers to compare.
final class RankingPeriodWindow {
  const RankingPeriodWindow({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  bool matches(DateTime otherStart, DateTime otherEnd) =>
      start.isAtSameMomentAs(otherStart) && end.isAtSameMomentAs(otherEnd);

  @override
  bool operator ==(Object other) =>
      other is RankingPeriodWindow &&
      start.isAtSameMomentAs(other.start) &&
      end.isAtSameMomentAs(other.end);

  @override
  int get hashCode => Object.hash(start, end);
}
