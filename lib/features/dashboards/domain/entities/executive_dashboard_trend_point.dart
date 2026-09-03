/// One point of the Executive Dashboard's revenue trend sparkline
/// (TASK-134): a single day's net revenue within the filtered month, read
/// straight from a `salesDaily` [AggregationSnapshot] (TASK-133) — never
/// computed client-side.
final class ExecutiveDashboardTrendPoint {
  const ExecutiveDashboardTrendPoint({required this.day, required this.value});

  final DateTime day;
  final double value;

  @override
  bool operator ==(Object other) {
    return other is ExecutiveDashboardTrendPoint &&
        day == other.day &&
        value == other.value;
  }

  @override
  int get hashCode => Object.hash(day, value);
}
