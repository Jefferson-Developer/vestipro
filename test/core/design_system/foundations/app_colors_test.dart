import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

/// WCAG 2.x relative luminance of a single sRGB channel value in `[0, 1]`,
/// per https://www.w3.org/TR/WCAG21/#dfn-relative-luminance.
double _channelLuminance(double channel) {
  return channel <= 0.03928
      ? channel / 12.92
      : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
}

/// WCAG 2.x relative luminance of a [Color].
double _relativeLuminance(Color color) {
  final r = _channelLuminance((color.r * 255.0).round() / 255);
  final g = _channelLuminance((color.g * 255.0).round() / 255);
  final b = _channelLuminance((color.b * 255.0).round() / 255);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// WCAG 2.x contrast ratio between two colors, per
/// https://www.w3.org/TR/WCAG21/#dfn-contrast-ratio. Always >= 1.
double _contrastRatio(Color a, Color b) {
  final luminanceA = _relativeLuminance(a);
  final luminanceB = _relativeLuminance(b);
  final lighter = math.max(luminanceA, luminanceB);
  final darker = math.min(luminanceA, luminanceB);
  return (lighter + 0.05) / (darker + 0.05);
}

/// WCAG AA minimum contrast ratio for normal-weight body text.
const double _wcagAaNormalText = 4.5;

void main() {
  group('AppColors contrast (WCAG AA)', () {
    test('light onSurface over surface meets 4.5:1', () {
      expect(
        _contrastRatio(AppColors.light.onSurface, AppColors.light.surface),
        greaterThanOrEqualTo(_wcagAaNormalText),
      );
    });

    test('light onPrimary over primary meets 4.5:1', () {
      expect(
        _contrastRatio(AppColors.light.onPrimary, AppColors.light.primary),
        greaterThanOrEqualTo(_wcagAaNormalText),
      );
    });

    test('dark onSurface over surface meets 4.5:1', () {
      expect(
        _contrastRatio(AppColors.dark.onSurface, AppColors.dark.surface),
        greaterThanOrEqualTo(_wcagAaNormalText),
      );
    });

    test('dark onPrimary over primary meets 4.5:1', () {
      expect(
        _contrastRatio(AppColors.dark.onPrimary, AppColors.dark.primary),
        greaterThanOrEqualTo(_wcagAaNormalText),
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
        _relativeLuminance(start.primary),
        closeTo(_relativeLuminance(AppColors.light.primary), 0.001),
      );
      expect(
        _relativeLuminance(end.primary),
        closeTo(_relativeLuminance(AppColors.dark.primary), 0.001),
      );
    });

    test('lerp returns itself when given no other extension to blend with', () {
      expect(AppColors.light.lerp(null, 0.5), AppColors.light);
    });
  });
}
