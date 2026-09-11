import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/fulfillment/fulfillment.dart';

void main() {
  group('TrackingEventType.fromCode/code round-trip', () {
    test('round-trips every server-known code', () {
      for (final type in TrackingEventType.values) {
        expect(TrackingEventType.fromCode(type.code), type);
      }
    });

    test('throws for an unknown code', () {
      expect(
        () => TrackingEventType.fromCode('teleported'),
        throwsArgumentError,
      );
    });
  });

  group('TrackingEventSource.fromCode/code round-trip', () {
    test('round-trips every server-known code', () {
      for (final source in TrackingEventSource.values) {
        expect(TrackingEventSource.fromCode(source.code), source);
      }
    });

    test('throws for an unknown code', () {
      expect(
        () => TrackingEventSource.fromCode('carrier-pigeon'),
        throwsArgumentError,
      );
    });
  });
}
