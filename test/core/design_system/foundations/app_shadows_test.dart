import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

void main() {
  group('AppShadows', () {
    test('resolve returns light for Brightness.light', () {
      expect(AppShadows.resolve(Brightness.light), AppShadows.light);
    });

    test('resolve returns dark for Brightness.dark', () {
      expect(AppShadows.resolve(Brightness.dark), AppShadows.dark);
    });

    test('elevation increases from sm to xl in both themes', () {
      for (final shadows in [AppShadows.light, AppShadows.dark]) {
        expect(
          shadows.sm.first.blurRadius,
          lessThan(shadows.md.first.blurRadius),
        );
        expect(
          shadows.md.first.blurRadius,
          lessThan(shadows.lg.first.blurRadius),
        );
        expect(
          shadows.lg.first.blurRadius,
          lessThan(shadows.xl.first.blurRadius),
        );
      }
    });

    test('dark shadows carry more opacity than light at every level, so '
        'elevation never "disappears" against a dark surface', () {
      expect(
        AppShadows.dark.sm.first.color.a,
        greaterThan(AppShadows.light.sm.first.color.a),
      );
      expect(
        AppShadows.dark.md.first.color.a,
        greaterThan(AppShadows.light.md.first.color.a),
      );
      expect(
        AppShadows.dark.lg.first.color.a,
        greaterThan(AppShadows.light.lg.first.color.a),
      );
      expect(
        AppShadows.dark.xl.first.color.a,
        greaterThan(AppShadows.light.xl.first.color.a),
      );
    });
  });
}
