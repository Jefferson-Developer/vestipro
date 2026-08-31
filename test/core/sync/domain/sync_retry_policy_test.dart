import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/sync/sync.dart';

void main() {
  group('SyncRetryPolicy', () {
    test('delayForAttempt doubles per attempt up to maxDelay', () {
      const policy = SyncRetryPolicy(
        baseDelay: Duration(seconds: 2),
        maxDelay: Duration(seconds: 20),
        maxAttempts: 10,
      );

      expect(policy.delayForAttempt(0), Duration.zero);
      expect(policy.delayForAttempt(1), const Duration(seconds: 2));
      expect(policy.delayForAttempt(2), const Duration(seconds: 4));
      expect(policy.delayForAttempt(3), const Duration(seconds: 8));
      expect(policy.delayForAttempt(4), const Duration(seconds: 16));
      // Capped at maxDelay from here on.
      expect(policy.delayForAttempt(5), const Duration(seconds: 20));
      expect(policy.delayForAttempt(6), const Duration(seconds: 20));
    });

    test('hasAttemptsLeft respects maxAttempts', () {
      const policy = SyncRetryPolicy(maxAttempts: 3);

      expect(policy.hasAttemptsLeft(0), isTrue);
      expect(policy.hasAttemptsLeft(2), isTrue);
      expect(policy.hasAttemptsLeft(3), isFalse);
      expect(policy.hasAttemptsLeft(4), isFalse);
    });

    test('isDueForRetry is true when never attempted before', () {
      const policy = SyncRetryPolicy();
      expect(
        policy.isDueForRetry(
          attemptCount: 0,
          lastAttemptAt: null,
          now: DateTime.utc(2026, 1, 1),
        ),
        isTrue,
      );
    });

    test('isDueForRetry is false before the backoff window elapses and true '
        'once it has', () {
      const policy = SyncRetryPolicy(baseDelay: Duration(seconds: 2));
      final lastAttemptAt = DateTime.utc(2026, 1, 1, 12, 0, 0);

      expect(
        policy.isDueForRetry(
          attemptCount: 1,
          lastAttemptAt: lastAttemptAt,
          now: lastAttemptAt.add(const Duration(seconds: 1)),
        ),
        isFalse,
      );
      expect(
        policy.isDueForRetry(
          attemptCount: 1,
          lastAttemptAt: lastAttemptAt,
          now: lastAttemptAt.add(const Duration(seconds: 2)),
        ),
        isTrue,
      );
    });
  });
}
