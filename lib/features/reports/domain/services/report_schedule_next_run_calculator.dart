import '../entities/report_schedule.dart';

/// Fixed UTC offset for `America/Sao_Paulo` — Brazil has not observed
/// daylight saving time since 2019, so every scheduled Cloud Function in
/// this codebase (`generateInsightsScheduled`, `expireStockReservations`,
/// `recomputeMonthlyAggregatesScheduled`) already treats it as a constant
/// offset rather than pulling in a full timezone database. Kept as its own
/// constant instead of inlining `3` so `ReportScheduleNextRunCalculator` and
/// its TypeScript mirror (`functions/src/reports/report-schedules-shared.ts`)
/// stay grep-ably in sync.
const int reportScheduleSaoPauloUtcOffsetHours = 3;

/// Computes when a [ReportSchedule] (TASK-149) is next due, expressed as a
/// UTC [DateTime] — always strictly after [from].
///
/// Mirrors `computeNextRunAt` in
/// `functions/src/reports/report-schedules-shared.ts` field-for-field: the
/// Cloud Function is the only side that ever *persists* `nextRunAt` after
/// the first cycle (every subsequent advance happens inside
/// `runReportSchedules`'s claim transaction), but `CreateReportSchedule`
/// still needs this exact same math client-side to seed the very first
/// `nextRunAt` a newly created schedule gets.
abstract final class ReportScheduleNextRunCalculator {
  static DateTime compute({
    required ReportScheduleFrequency frequency,
    int? weekday,
    int? dayOfMonth,
    required int hour,
    required int minute,
    required DateTime from,
  }) {
    final fromWallClock = _toSaoPauloWallClock(from);
    var candidate = DateTime.utc(
      fromWallClock.year,
      fromWallClock.month,
      fromWallClock.day,
      hour,
      minute,
    );

    switch (frequency) {
      case ReportScheduleFrequency.daily:
        if (!candidate.isAfter(fromWallClock)) {
          candidate = candidate.add(const Duration(days: 1));
        }
      case ReportScheduleFrequency.weekly:
        final targetWeekday = weekday ?? DateTime.monday;
        var deltaDays = (targetWeekday - candidate.weekday + 7) % 7;
        if (deltaDays == 0 && !candidate.isAfter(fromWallClock)) {
          deltaDays = 7;
        }
        candidate = candidate.add(Duration(days: deltaDays));
      case ReportScheduleFrequency.monthly:
        final targetDay = (dayOfMonth ?? 1).clamp(1, 28);
        candidate = DateTime.utc(
          fromWallClock.year,
          fromWallClock.month,
          targetDay,
          hour,
          minute,
        );
        if (!candidate.isAfter(fromWallClock)) {
          candidate = DateTime.utc(
            fromWallClock.year,
            fromWallClock.month + 1,
            targetDay,
            hour,
            minute,
          );
        }
    }

    return _fromSaoPauloWallClock(candidate);
  }

  /// A stable identifier for the scheduled cycle whose due instant is
  /// [nextRunAt] — the idempotency key `runReportSchedules`'s claim
  /// transaction checks before ever generating a delivery, and the same key
  /// a Cloud Scheduler retry (re-observing the same due schedule before the
  /// claim's `nextRunAt` advance is visible) must resolve to identically, so
  /// it never double-sends.
  static String cycleKeyFor(DateTime nextRunAt) =>
      nextRunAt.toUtc().toIso8601String();

  static DateTime _toSaoPauloWallClock(DateTime instant) => instant
      .toUtc()
      .subtract(const Duration(hours: reportScheduleSaoPauloUtcOffsetHours));

  static DateTime _fromSaoPauloWallClock(DateTime wallClock) => wallClock.add(
    const Duration(hours: reportScheduleSaoPauloUtcOffsetHours),
  );
}
