import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

void main() {
  group('AppRadius', () {
    test('exposes exactly the scale defined in tasks.md 6.1', () {
      expect(AppRadius.scale, <double>[4, 8, 12, 16, 20, 24]);
    });

    test('each named token matches its position in the scale', () {
      expect(AppRadius.radius4, 4);
      expect(AppRadius.radius8, 8);
      expect(AppRadius.radius12, 12);
      expect(AppRadius.radius16, 16);
      expect(AppRadius.radius20, 20);
      expect(AppRadius.radius24, 24);
    });

    test('full is a distinct, larger-than-scale pill token', () {
      expect(AppRadius.full, greaterThan(AppRadius.scale.last));
      expect(AppRadius.scale.contains(AppRadius.full), isFalse);
    });

    test('scale has no duplicates and is strictly ascending', () {
      expect(AppRadius.scale.toSet().length, AppRadius.scale.length);
      for (var i = 1; i < AppRadius.scale.length; i++) {
        expect(AppRadius.scale[i], greaterThan(AppRadius.scale[i - 1]));
      }
    });
  });
}
