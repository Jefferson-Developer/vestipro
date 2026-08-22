import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

void main() {
  group('AppTypography', () {
    test('uses the same defined fontFamily across the whole scale', () {
      const styles = <String, TextStyle>{
        'displayLarge': AppTypography.displayLarge,
        'displayMedium': AppTypography.displayMedium,
        'headlineLarge': AppTypography.headlineLarge,
        'headlineMedium': AppTypography.headlineMedium,
        'titleLarge': AppTypography.titleLarge,
        'titleMedium': AppTypography.titleMedium,
        'bodyLarge': AppTypography.bodyLarge,
        'bodyMedium': AppTypography.bodyMedium,
        'bodySmall': AppTypography.bodySmall,
        'labelLarge': AppTypography.labelLarge,
        'labelMedium': AppTypography.labelMedium,
        'labelSmall': AppTypography.labelSmall,
      };

      for (final entry in styles.entries) {
        expect(
          entry.value.fontFamily,
          AppTypography.fontFamily,
          reason: '${entry.key} must use AppTypography.fontFamily',
        );
      }
    });

    test('font sizes strictly decrease from display down to label', () {
      expect(
        AppTypography.displayLarge.fontSize,
        greaterThan(AppTypography.displayMedium.fontSize!),
      );
      expect(
        AppTypography.displayMedium.fontSize,
        greaterThan(AppTypography.headlineLarge.fontSize!),
      );
      expect(
        AppTypography.headlineLarge.fontSize,
        greaterThan(AppTypography.headlineMedium.fontSize!),
      );
      expect(
        AppTypography.headlineMedium.fontSize,
        greaterThan(AppTypography.titleLarge.fontSize!),
      );
      expect(
        AppTypography.titleLarge.fontSize,
        greaterThanOrEqualTo(AppTypography.titleMedium.fontSize!),
      );
      expect(
        AppTypography.bodyLarge.fontSize,
        greaterThan(AppTypography.bodySmall.fontSize!),
      );
    });

    test('textTheme applies the given AppColors.onSurface to every style', () {
      final textTheme = AppTypography.textTheme(AppColors.dark);

      expect(textTheme.displayLarge?.color, AppColors.dark.onSurface);
      expect(textTheme.headlineMedium?.color, AppColors.dark.onSurface);
      expect(textTheme.titleLarge?.color, AppColors.dark.onSurface);
      expect(textTheme.bodyMedium?.color, AppColors.dark.onSurface);
      expect(textTheme.labelSmall?.color, AppColors.dark.onSurface);
    });
  });
}
