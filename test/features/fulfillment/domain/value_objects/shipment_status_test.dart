import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/fulfillment/fulfillment.dart';

void main() {
  group('ShipmentStatus.fromCode/code round-trip', () {
    test('round-trips every server-known code', () {
      for (final status in ShipmentStatus.values) {
        expect(ShipmentStatus.fromCode(status.code), status);
      }
    });

    test('throws for an unknown code', () {
      expect(() => ShipmentStatus.fromCode('teleported'), throwsArgumentError);
    });
  });

  group('ShipmentStatus.isOpen', () {
    test('is false only for delivered/returned/cancelled', () {
      expect(ShipmentStatus.delivered.isOpen, isFalse);
      expect(ShipmentStatus.returned.isOpen, isFalse);
      expect(ShipmentStatus.cancelled.isOpen, isFalse);
    });

    test('is true for every other status', () {
      for (final status in ShipmentStatus.values) {
        if (status == ShipmentStatus.delivered ||
            status == ShipmentStatus.returned ||
            status == ShipmentStatus.cancelled) {
          continue;
        }
        expect(status.isOpen, isTrue, reason: '$status must be open');
      }
    });
  });
}
