import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/backorder/backorder.dart';

void main() {
  group('BackorderStatus.fromCode/code round-trip', () {
    test('round-trips every server-known code', () {
      for (final status in BackorderStatus.values) {
        expect(BackorderStatus.fromCode(status.code), status);
      }
    });

    test('throws for an unknown code', () {
      expect(() => BackorderStatus.fromCode('teleported'), throwsArgumentError);
    });
  });

  group('BackorderStatus.isOpen', () {
    test('is true for requested/awaitingApproval/queued/readyToFulfill', () {
      expect(BackorderStatus.requested.isOpen, isTrue);
      expect(BackorderStatus.awaitingApproval.isOpen, isTrue);
      expect(BackorderStatus.queued.isOpen, isTrue);
      expect(BackorderStatus.readyToFulfill.isOpen, isTrue);
    });

    test('is false for converted/rejected/cancelled (terminal statuses)', () {
      expect(BackorderStatus.converted.isOpen, isFalse);
      expect(BackorderStatus.rejected.isOpen, isFalse);
      expect(BackorderStatus.cancelled.isOpen, isFalse);
    });
  });

  group('BackorderStatus.isQueueable', () {
    test('is true only for queued/readyToFulfill', () {
      expect(BackorderStatus.queued.isQueueable, isTrue);
      expect(BackorderStatus.readyToFulfill.isQueueable, isTrue);
    });

    test('is false for every other status, including awaitingApproval', () {
      for (final status in BackorderStatus.values) {
        if (status == BackorderStatus.queued ||
            status == BackorderStatus.readyToFulfill) {
          continue;
        }
        expect(
          status.isQueueable,
          isFalse,
          reason: '$status must not be queueable',
        );
      }
    });
  });
}
