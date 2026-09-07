import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

void main() {
  group('AppBrandTheme.resolveColors', () {
    test('returns base unchanged when primaryColorHex is null', () {
      final result = AppBrandTheme.resolveColors(
        base: AppColors.light,
        primaryColorHex: null,
      );

      expect(result, AppColors.light);
    });

    test('returns base unchanged when primaryColorHex is blank', () {
      final result = AppBrandTheme.resolveColors(
        base: AppColors.light,
        primaryColorHex: '   ',
      );

      expect(result, AppColors.light);
    });

    test('returns base unchanged for a malformed hex string', () {
      final result = AppBrandTheme.resolveColors(
        base: AppColors.light,
        primaryColorHex: 'not-a-color',
      );

      expect(result, AppColors.light);
    });

    test('applies a valid, dark custom primary color keeping the base '
        'onPrimary (already readable against it)', () {
      final result = AppBrandTheme.resolveColors(
        base: AppColors.light,
        primaryColorHex: '#0A1F33',
      );

      expect(result.primary, const Color(0xFF0A1F33));
      expect(result.onPrimary, AppColors.light.onPrimary);
      expect(AppContrast.meetsWcagAa(result.onPrimary, result.primary), isTrue);
      // Every other token stays untouched.
      expect(result.secondary, AppColors.light.secondary);
      expect(result.surface, AppColors.light.surface);
    });

    test('swaps onPrimary to a readable color when the base onPrimary fails '
        'contrast against a bright custom primary', () {
      // Bright yellow: white (the light theme's own onPrimary) fails
      // WCAG AA against it, black passes.
      final result = AppBrandTheme.resolveColors(
        base: AppColors.light,
        primaryColorHex: '#FFEB3B',
      );

      expect(result.primary, const Color(0xFFFFEB3B));
      expect(result.onPrimary, isNot(AppColors.light.onPrimary));
      expect(AppContrast.meetsWcagAa(result.onPrimary, result.primary), isTrue);
    });

    test('never leaks one organization theme into another\'s resolution', () {
      final orgA = AppBrandTheme.resolveColors(
        base: AppColors.light,
        primaryColorHex: '#0A1F33',
      );
      final orgB = AppBrandTheme.resolveColors(
        base: AppColors.light,
        primaryColorHex: '#2B1030',
      );

      expect(orgA.primary, isNot(orgB.primary));
      expect(orgA.primary, const Color(0xFF0A1F33));
      expect(orgB.primary, const Color(0xFF2B1030));
    });
  });

  group('AppBrandTheme.needsContrastFallback', () {
    test('is false when primaryColorHex is null/blank', () {
      expect(
        AppBrandTheme.needsContrastFallback(
          base: AppColors.light,
          primaryColorHex: null,
        ),
        isFalse,
      );
      expect(
        AppBrandTheme.needsContrastFallback(
          base: AppColors.light,
          primaryColorHex: '  ',
        ),
        isFalse,
      );
    });

    test('is false for a valid color that keeps the base onPrimary', () {
      expect(
        AppBrandTheme.needsContrastFallback(
          base: AppColors.light,
          primaryColorHex: '#0A1F33',
        ),
        isFalse,
      );
    });

    test('is true for a malformed hex string', () {
      expect(
        AppBrandTheme.needsContrastFallback(
          base: AppColors.light,
          primaryColorHex: 'purple',
        ),
        isTrue,
      );
    });

    test(
      'is true for a valid color that forces the onPrimary text to swap',
      () {
        expect(
          AppBrandTheme.needsContrastFallback(
            base: AppColors.light,
            primaryColorHex: '#FFEB3B',
          ),
          isTrue,
        );
      },
    );
  });

  group('AppBrandTheme.resolveTheme', () {
    test('builds a light ThemeData using the branded color when valid', () {
      final theme = AppBrandTheme.resolveTheme(
        brightness: Brightness.light,
        primaryColorHex: '#0A1F33',
      );

      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, const Color(0xFF0A1F33));
    });

    test('builds a dark ThemeData falling back when hex is malformed', () {
      final theme = AppBrandTheme.resolveTheme(
        brightness: Brightness.dark,
        primaryColorHex: 'invalid',
      );

      expect(theme.brightness, Brightness.dark);
      expect(theme.extension<AppColors>(), AppColors.dark);
    });

    test(
      'is the same assembly as AppTheme.fromColors (no duplicated tree)',
      () {
        final branded = AppBrandTheme.resolveTheme(
          brightness: Brightness.light,
          primaryColorHex: null,
        );

        expect(branded.colorScheme, AppTheme.light.colorScheme);
      },
    );
  });
}
