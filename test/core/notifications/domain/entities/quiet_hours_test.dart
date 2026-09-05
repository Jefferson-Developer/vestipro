import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/notifications/notifications.dart';

void main() {
  group('QuietHours', () {
    test(
      'is never active when disabled, even inside the configured window',
      () {
        const quietHours = QuietHours(timezoneOffsetMinutes: 0);

        expect(quietHours.isActiveAt(DateTime.utc(2026, 1, 16, 23)), isFalse);
      },
    );

    test('an overnight window (22:00-07:00) is active during the evening part '
        'of the day it starts on', () {
      const quietHours = QuietHours(enabled: true, timezoneOffsetMinutes: 0);

      // 2026-01-16 is a Friday.
      expect(quietHours.isActiveAt(DateTime.utc(2026, 1, 16, 23)), isTrue);
      expect(quietHours.isActiveAt(DateTime.utc(2026, 1, 16, 21, 59)), isFalse);
    });

    test('an overnight window is active during the morning part of the day '
        'after it started, and checks that previous day\'s weekday', () {
      const quietHours = QuietHours(
        enabled: true,
        timezoneOffsetMinutes: 0,
        // Only Friday is active — the early hours of Saturday still
        // belong to Friday night's window.
        activeWeekdays: <int>{DateTime.friday},
      );

      // 2026-01-17 06:00 is Saturday morning, right after a Friday night.
      expect(quietHours.isActiveAt(DateTime.utc(2026, 1, 17, 6)), isTrue);
      // 2026-01-17 23:00 is Saturday night — not an active weekday.
      expect(quietHours.isActiveAt(DateTime.utc(2026, 1, 17, 23)), isFalse);
      // 2026-01-17 07:01 is past the window's end.
      expect(quietHours.isActiveAt(DateTime.utc(2026, 1, 17, 7, 1)), isFalse);
    });

    test('a non-overnight window (e.g. 13:00-14:00) is active only strictly '
        'between start and end', () {
      const quietHours = QuietHours(
        enabled: true,
        startMinuteOfDay: 13 * 60,
        endMinuteOfDay: 14 * 60,
        timezoneOffsetMinutes: 0,
      );

      expect(quietHours.isActiveAt(DateTime.utc(2026, 1, 16, 13, 30)), isTrue);
      expect(quietHours.isActiveAt(DateTime.utc(2026, 1, 16, 12, 59)), isFalse);
      expect(quietHours.isActiveAt(DateTime.utc(2026, 1, 16, 14)), isFalse);
    });

    test(
      'evaluates the recipient\'s own local time from timezoneOffsetMinutes, '
      'never the UTC instant directly',
      () {
        // UTC-3 (Brazil): 23:00 UTC is 20:00 local — outside the default
        // 22:00-07:00 window.
        const quietHours = QuietHours(
          enabled: true,
          timezoneOffsetMinutes: -180,
        );

        expect(quietHours.isActiveAt(DateTime.utc(2026, 1, 16, 23)), isFalse);
        // 01:00 UTC is 22:00 local the previous day — inside the window.
        expect(quietHours.isActiveAt(DateTime.utc(2026, 1, 17, 1)), isTrue);
      },
    );

    test('nextAllowedInstant resolves to the end of the evening part\'s window '
        '(next calendar day) for an overnight window', () {
      const quietHours = QuietHours(enabled: true, timezoneOffsetMinutes: 0);

      expect(
        quietHours.nextAllowedInstant(DateTime.utc(2026, 1, 16, 23)),
        DateTime.utc(2026, 1, 17, 7),
      );
    });

    test('nextAllowedInstant resolves to the end of the morning part\'s window '
        '(same calendar day) for an overnight window', () {
      const quietHours = QuietHours(enabled: true, timezoneOffsetMinutes: 0);

      expect(
        quietHours.nextAllowedInstant(DateTime.utc(2026, 1, 17, 3)),
        DateTime.utc(2026, 1, 17, 7),
      );
    });

    test('nextAllowedInstant respects a non-zero recipient offset', () {
      const quietHours = QuietHours(enabled: true, timezoneOffsetMinutes: -180);

      // 01:00 UTC == 22:00 local (previous day) -> ends at 07:00 local the
      // same local day == 10:00 UTC.
      expect(
        quietHours.nextAllowedInstant(DateTime.utc(2026, 1, 17, 1)),
        DateTime.utc(2026, 1, 17, 10),
      );
    });

    test('rejects a window with an equal start and end', () {
      expect(
        () => QuietHours(startMinuteOfDay: 60, endMinuteOfDay: 60),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
