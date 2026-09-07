import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

// WCAG contrast math (relative luminance/ratio) lives in [AppContrast]
// (TASK-179) — reused here instead of re-derived, so tests and production
// code (e.g. `AppBrandTheme`'s white-label contrast fallback) share a single
// implementation of https://www.w3.org/TR/WCAG21/#dfn-contrast-ratio.

void main() {
  group('AppColors contrast (WCAG AA)', () {
    test('light onSurface over surface meets 4.5:1', () {
      expect(
        AppContrast.ratio(AppColors.light.onSurface, AppColors.light.surface),
        greaterThanOrEqualTo(AppContrast.wcagAaNormalText),
      );
    });

    test('light onPrimary over primary meets 4.5:1', () {
      expect(
        AppContrast.ratio(AppColors.light.onPrimary, AppColors.light.primary),
        greaterThanOrEqualTo(AppContrast.wcagAaNormalText),
      );
    });

    test('dark onSurface over surface meets 4.5:1', () {
      expect(
        AppContrast.ratio(AppColors.dark.onSurface, AppColors.dark.surface),
        greaterThanOrEqualTo(AppContrast.wcagAaNormalText),
      );
    });

    test('dark onPrimary over primary meets 4.5:1', () {
      expect(
        AppContrast.ratio(AppColors.dark.onPrimary, AppColors.dark.primary),
        greaterThanOrEqualTo(AppContrast.wcagAaNormalText),
      );
    });
  });

  group('AppColors', () {
    test('light and dark define distinct values for every token', () {
      expect(AppColors.light.primary, isNot(AppColors.dark.primary));
      expect(AppColors.light.surface, isNot(AppColors.dark.surface));
      expect(AppColors.light.background, isNot(AppColors.dark.background));
      expect(AppColors.light.onSurface, isNot(AppColors.dark.onSurface));
    });

    test('copyWith overrides only the requested token', () {
      const override = Color(0xFF00FF00);
      final result = AppColors.light.copyWith(primary: override);

      expect(result.primary, override);
      expect(result.secondary, AppColors.light.secondary);
      expect(result.surface, AppColors.light.surface);
    });

    test('lerp at t=0 returns the start value and at t=1 the end value', () {
      final start = AppColors.light.lerp(AppColors.dark, 0);
      final end = AppColors.light.lerp(AppColors.dark, 1);

      // `Color.lerp` special-cases the endpoints exactly, but comparing
      // through floating-point channels stays safe with a tight tolerance
      // instead of assuming bit-for-bit `Color` equality.
      expect(
        AppContrast.relativeLuminance(start.primary),
        closeTo(AppContrast.relativeLuminance(AppColors.light.primary), 0.001),
      );
      expect(
        AppContrast.relativeLuminance(end.primary),
        closeTo(AppContrast.relativeLuminance(AppColors.dark.primary), 0.001),
      );
    });

    test('lerp returns itself when given no other extension to blend with', () {
      expect(AppColors.light.lerp(null, 0.5), AppColors.light);
    });
  });
}
