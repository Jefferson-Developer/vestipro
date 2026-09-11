import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/backorder/backorder.dart';

void main() {
  group('BackorderPriority.fromCode/code round-trip', () {
    test('round-trips every server-known code', () {
      for (final priority in BackorderPriority.values) {
        expect(BackorderPriority.fromCode(priority.code), priority);
      }
    });

    test('throws for an unknown code', () {
      expect(() => BackorderPriority.fromCode('critical'), throwsArgumentError);
    });
  });

  group('BackorderPriority.weight', () {
    test('ranks urgent > high > normal > low', () {
      expect(
        BackorderPriority.urgent.weight,
        greaterThan(BackorderPriority.high.weight),
      );
      expect(
        BackorderPriority.high.weight,
        greaterThan(BackorderPriority.normal.weight),
      );
      expect(
        BackorderPriority.normal.weight,
        greaterThan(BackorderPriority.low.weight),
      );
    });
  });
}
