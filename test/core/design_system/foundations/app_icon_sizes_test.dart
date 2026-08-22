import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

void main() {
  group('AppIconSizes', () {
    test('exposes exactly the documented scale', () {
      expect(AppIconSizes.scale, <double>[16, 20, 24, 32, 40]);
    });

    test('each named token matches its position in the scale', () {
      expect(AppIconSizes.sm, 16);
      expect(AppIconSizes.md, 20);
      expect(AppIconSizes.lg, 24);
      expect(AppIconSizes.xl, 32);
      expect(AppIconSizes.xxl, 40);
    });

    test('scale has no duplicates and is strictly ascending', () {
      expect(AppIconSizes.scale.toSet().length, AppIconSizes.scale.length);
      for (var i = 1; i < AppIconSizes.scale.length; i++) {
        expect(AppIconSizes.scale[i], greaterThan(AppIconSizes.scale[i - 1]));
      }
    });
  });
}
