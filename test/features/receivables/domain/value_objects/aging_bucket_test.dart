import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/receivables/receivables.dart';

void main() {
  final now = DateTime.utc(2026, 6, 15, 12);

  group('agingBucketFor', () {
    test('is current for a settled receivable regardless of due date', () {
      expect(
        agingBucketFor(
          dueDate: now.subtract(const Duration(days: 200)),
          isSettled: true,
          now: now,
        ),
        AgingBucket.current,
      );
    });

    test('is current for a not-yet-due receivable', () {
      expect(
        agingBucketFor(
          dueDate: now.add(const Duration(days: 5)),
          isSettled: false,
          now: now,
        ),
        AgingBucket.current,
      );
    });

    test('buckets days past due into the correct range', () {
      expect(
        agingBucketFor(
          dueDate: now.subtract(const Duration(days: 5)),
          isSettled: false,
          now: now,
        ),
        AgingBucket.d1to30,
      );
      expect(
        agingBucketFor(
          dueDate: now.subtract(const Duration(days: 45)),
          isSettled: false,
          now: now,
        ),
        AgingBucket.d31to60,
      );
      expect(
        agingBucketFor(
          dueDate: now.subtract(const Duration(days: 75)),
          isSettled: false,
          now: now,
        ),
        AgingBucket.d61to90,
      );
      expect(
        agingBucketFor(
          dueDate: now.subtract(const Duration(days: 120)),
          isSettled: false,
          now: now,
        ),
        AgingBucket.d90plus,
      );
    });
  });
}
