import 'package:flutter/material.dart';

import '../foundations/foundations.dart';

/// Builds the light and dark [ThemeData] for the whole app from the Design
/// System foundations — the single place allowed to assemble a [ThemeData].
/// No feature is allowed to build its own [ThemeData]/[ColorScheme].
///
/// Wire both into [MaterialApp]/[MaterialApp.router] as:
///
/// ```dart
/// MaterialApp.router(
///   theme: AppTheme.light,
///   darkTheme: AppTheme.dark,
///   themeMode: ThemeMode.system,
///   ...
/// )
/// ```
abstract final class AppTheme {
  const AppTheme._();

  static ThemeData get light => fromColors(AppColors.light, Brightness.light);

  static ThemeData get dark => fromColors(AppColors.dark, Brightness.dark);

  /// Builds a full [ThemeData] from an already-resolved [colors] token set —
  /// the single assembly [light]/[dark] delegate to, and the same one a
  /// per-organization white-label theme (`AppBrandTheme.resolveTheme`,
  /// TASK-179) reuses, so a customized theme is never a second, divergent
  /// `ThemeData` construction path.
  static ThemeData fromColors(AppColors colors, Brightness brightness) {
    // `ColorScheme.fromSeed` fills in every Material 3 role (tertiary,
    // outlineVariant, inverseSurface, scrim, ...) with values consistent
    // with `brightness`; the explicit tokens below then override the roles
    // the Design System actually names, so the brand palette always wins.
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: colors.primary,
          brightness: brightness,
        ).copyWith(
          primary: colors.primary,
          onPrimary: colors.onPrimary,
          primaryContainer: colors.primaryContainer,
          secondary: colors.secondary,
          secondaryContainer: colors.secondaryContainer,
          surface: colors.surface,
          onSurface: colors.onSurface,
          error: colors.error,
          outline: colors.outline,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      textTheme: AppTypography.textTheme(colors),
      iconTheme: IconThemeData(color: colors.onSurface, size: AppIconSizes.lg),
      disabledColor: colors.disabled,
      dividerColor: colors.outline,
      // Registers the token set itself so any widget can read the exact
      // semantic tokens (not just the Material roles above) via
      // `Theme.of(context).extension<AppColors>()`.
      extensions: <ThemeExtension<dynamic>>[colors],
    );
  }
}
