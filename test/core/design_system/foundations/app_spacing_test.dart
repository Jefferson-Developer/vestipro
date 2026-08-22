import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

void main() {
  group('AppSpacing', () {
    test('exposes exactly the base-4 scale defined in tasks.md 6.1', () {
      expect(AppSpacing.scale, <double>[4, 8, 12, 16, 20, 24, 32, 40, 48, 64]);
    });

    test('each named token matches its position in the scale', () {
      expect(AppSpacing.spacing4, 4);
      expect(AppSpacing.spacing8, 8);
      expect(AppSpacing.spacing12, 12);
      expect(AppSpacing.spacing16, 16);
      expect(AppSpacing.spacing20, 20);
      expect(AppSpacing.spacing24, 24);
      expect(AppSpacing.spacing32, 32);
      expect(AppSpacing.spacing40, 40);
      expect(AppSpacing.spacing48, 48);
      expect(AppSpacing.spacing64, 64);
    });

    test('scale has no duplicates and is strictly ascending', () {
      expect(AppSpacing.scale.toSet().length, AppSpacing.scale.length);
      for (var i = 1; i < AppSpacing.scale.length; i++) {
        expect(AppSpacing.scale[i], greaterThan(AppSpacing.scale[i - 1]));
      }
    });
  });
}
