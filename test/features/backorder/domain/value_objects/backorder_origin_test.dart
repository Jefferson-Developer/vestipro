import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/backorder/backorder.dart';

void main() {
  group('BackorderOrigin.fromCode/code round-trip', () {
    test('round-trips every server-known code', () {
      for (final origin in BackorderOrigin.values) {
        expect(BackorderOrigin.fromCode(origin.code), origin);
      }
    });

    test('throws for an unknown code', () {
      expect(() => BackorderOrigin.fromCode('bogus'), throwsArgumentError);
    });
  });
}
