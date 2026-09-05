import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/reports/reports.dart';

void main() {
  group('ReportScheduleNextRunCalculator (TASK-149)', () {
    test('daily: rolls to the next day when the time already passed today', () {
      // 2026-09-05 12:00 UTC = 09:00 em São Paulo (UTC-3).
      final from = DateTime.utc(2026, 9, 5, 12);
      final next = ReportScheduleNextRunCalculator.compute(
        frequency: ReportScheduleFrequency.daily,
        hour: 8,
        minute: 0,
        from: from,
      );
      expect(next, DateTime.utc(2026, 9, 6, 11));
    });

    test('daily: same day when the time has not passed yet', () {
      final from = DateTime.utc(2026, 9, 5, 10); // 07:00 São Paulo
      final next = ReportScheduleNextRunCalculator.compute(
        frequency: ReportScheduleFrequency.daily,
        hour: 8,
        minute: 0,
        from: from,
      );
      expect(next, DateTime.utc(2026, 9, 5, 11));
    });

    test('weekly: finds the next occurrence of the target weekday', () {
      // 2026-09-05 é sábado (weekday ISO 6).
      final from = DateTime.utc(2026, 9, 5, 12);
      final next = ReportScheduleNextRunCalculator.compute(
        frequency: ReportScheduleFrequency.weekly,
        weekday: DateTime.monday,
        hour: 8,
        minute: 0,
        from: from,
      );
      expect(next, DateTime.utc(2026, 9, 7, 11));
    });

    test(
      'weekly: same weekday but time already passed rolls a full week forward',
      () {
        final from = DateTime.utc(2026, 9, 7, 12); // segunda-feira, 09:00 SP
        final next = ReportScheduleNextRunCalculator.compute(
          frequency: ReportScheduleFrequency.weekly,
          weekday: DateTime.monday,
          hour: 8,
          minute: 0,
          from: from,
        );
        expect(next, DateTime.utc(2026, 9, 14, 11));
      },
    );

    test('monthly: rolls to the next month when the day already passed', () {
      final from = DateTime.utc(2026, 9, 5, 12); // dia 5, 09:00 SP
      final next = ReportScheduleNextRunCalculator.compute(
        frequency: ReportScheduleFrequency.monthly,
        dayOfMonth: 1,
        hour: 8,
        minute: 0,
        from: from,
      );
      expect(next, DateTime.utc(2026, 10, 1, 11));
    });

    test(
      'monthly: clamps an out-of-range dayOfMonth to 28 so every month always has it',
      () {
        final from = DateTime.utc(2026, 1, 1);
        final next = ReportScheduleNextRunCalculator.compute(
          frequency: ReportScheduleFrequency.monthly,
          dayOfMonth: 31,
          hour: 8,
          minute: 0,
          from: from,
        );
        expect(next.day, 28);
      },
    );

    test('always returns an instant strictly after `from`', () {
      final from = DateTime.utc(2026, 9, 5, 11);
      for (final frequency in ReportScheduleFrequency.values) {
        final next = ReportScheduleNextRunCalculator.compute(
          frequency: frequency,
          weekday: DateTime.saturday,
          dayOfMonth: 5,
          hour: 8,
          minute: 0,
          from: from,
        );
        expect(next.isAfter(from), isTrue);
      }
    });

    test('cycleKeyFor is a deterministic ISO string of the due instant', () {
      final nextRunAt = DateTime.utc(2026, 9, 6, 11);
      expect(
        ReportScheduleNextRunCalculator.cycleKeyFor(nextRunAt),
        '2026-09-06T11:00:00.000Z',
      );
      expect(
        ReportScheduleNextRunCalculator.cycleKeyFor(nextRunAt),
        ReportScheduleNextRunCalculator.cycleKeyFor(
          DateTime.utc(2026, 9, 6, 11),
        ),
      );
    });
  });
}
