import '../value_objects/target_period_granularity.dart';

/// The `[start, end)` window of the current positivação period for
/// [granularity], as of [now] (TASK-117, EPIC-15/VESTI-087) — pure, no
/// `DateTime.now()` read internally, same testability precedent as
/// `TargetProgressViewModel.compute`.
///
/// [now] is always normalized to UTC first, so callers never need to worry
/// about local-time month/quarter/year boundaries drifting across timezones.
final class PositivacaoPeriod {
  const PositivacaoPeriod({required this.start, required this.end});

  final DateTime start;

  /// Exclusive end of the period.
  final DateTime end;

  static PositivacaoPeriod current({
    required TargetPeriodGranularity granularity,
    required DateTime now,
  }) {
    final utcNow = now.toUtc();
    return switch (granularity) {
      TargetPeriodGranularity.monthly => _monthly(utcNow),
      TargetPeriodGranularity.quarterly => _quarterly(utcNow),
      TargetPeriodGranularity.yearly => _yearly(utcNow),
    };
  }

  static PositivacaoPeriod _monthly(DateTime utcNow) {
    final start = DateTime.utc(utcNow.year, utcNow.month);
    final end = DateTime.utc(utcNow.year, utcNow.month + 1);
    return PositivacaoPeriod(start: start, end: end);
  }

  static PositivacaoPeriod _quarterly(DateTime utcNow) {
    final quarterStartMonth = ((utcNow.month - 1) ~/ 3) * 3 + 1;
    final start = DateTime.utc(utcNow.year, quarterStartMonth);
    final end = DateTime.utc(utcNow.year, quarterStartMonth + 3);
    return PositivacaoPeriod(start: start, end: end);
  }

  static PositivacaoPeriod _yearly(DateTime utcNow) {
    final start = DateTime.utc(utcNow.year);
    final end = DateTime.utc(utcNow.year + 1);
    return PositivacaoPeriod(start: start, end: end);
  }
}
