import 'package:flutter/material.dart';

/// Semantic color tokens for the VestiPro Design System.
///
/// [AppColors] is the *only* place allowed to define a [Color] literal in
/// the app: no widget, page or feature may hardcode a color value directly.
/// Every token below is defined for both [light] and [dark] and the pairs
/// most used for text-on-background (`onSurface`/`surface`,
/// `onPrimary`/`primary`) are validated against WCAG AA contrast in
/// `test/core/design_system/foundations/app_colors_test.dart`.
///
/// Registered as a [ThemeExtension] so it travels with [ThemeData] and can
/// be read anywhere via `Theme.of(context).extension<AppColors>()` (or the
/// `context.colors` convenience getter in `design_system_context.dart`).
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primary,
    required this.primaryContainer,
    required this.secondary,
    required this.secondaryContainer,
    required this.surface,
    required this.surfaceContainer,
    required this.background,
    required this.error,
    required this.success,
    required this.warning,
    required this.info,
    required this.onPrimary,
    required this.onSurface,
    required this.outline,
    required this.disabled,
  });

  final Color primary;
  final Color primaryContainer;
  final Color secondary;
  final Color secondaryContainer;
  final Color surface;
  final Color surfaceContainer;
  final Color background;
  final Color error;
  final Color success;
  final Color warning;
  final Color info;
  final Color onPrimary;
  final Color onSurface;
  final Color outline;
  final Color disabled;

  /// Light theme tokens: an airy, high-contrast, editorial fashion feel.
  static const AppColors light = AppColors(
    primary: Color(0xFF1F5364),
    primaryContainer: Color(0xFFD3E6EC),
    secondary: Color(0xFF8C6A4F),
    secondaryContainer: Color(0xFFEDE0D3),
    surface: Color(0xFFFFFFFF),
    surfaceContainer: Color(0xFFF4F2EF),
    background: Color(0xFFFBFAF8),
    error: Color(0xFFB3261E),
    success: Color(0xFF1E6B4E),
    warning: Color(0xFF8A5A00),
    info: Color(0xFF2A5DA8),
    onPrimary: Color(0xFFFFFFFF),
    onSurface: Color(0xFF1B1B1B),
    outline: Color(0xFF79747E),
    disabled: Color(0xFFBDBDBD),
  );

  /// Dark theme tokens. Shadows (`app_shadows.dart`) gain opacity instead of
  /// disappearing, and every token below still meets WCAG AA contrast
  /// against its expected background.
  static const AppColors dark = AppColors(
    primary: Color(0xFF8AC7DE),
    primaryContainer: Color(0xFF2B4C58),
    secondary: Color(0xFFD8B792),
    secondaryContainer: Color(0xFF4A3B2C),
    surface: Color(0xFF1C1C1E),
    surfaceContainer: Color(0xFF262629),
    background: Color(0xFF121212),
    error: Color(0xFFF2B8B5),
    success: Color(0xFF7FD9AF),
    warning: Color(0xFFFFC873),
    info: Color(0xFFA8C7FA),
    onPrimary: Color(0xFF00344A),
    onSurface: Color(0xFFE6E1E5),
    outline: Color(0xFF938F99),
    disabled: Color(0xFF5C5C5E),
  );

  @override
  AppColors copyWith({
    Color? primary,
    Color? primaryContainer,
    Color? secondary,
    Color? secondaryContainer,
    Color? surface,
    Color? surfaceContainer,
    Color? background,
    Color? error,
    Color? success,
    Color? warning,
    Color? info,
    Color? onPrimary,
    Color? onSurface,
    Color? outline,
    Color? disabled,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      secondary: secondary ?? this.secondary,
      secondaryContainer: secondaryContainer ?? this.secondaryContainer,
      surface: surface ?? this.surface,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      background: background ?? this.background,
      error: error ?? this.error,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      onPrimary: onPrimary ?? this.onPrimary,
      onSurface: onSurface ?? this.onSurface,
      outline: outline ?? this.outline,
      disabled: disabled ?? this.disabled,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }
    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryContainer: Color.lerp(
        primaryContainer,
        other.primaryContainer,
        t,
      )!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondaryContainer: Color.lerp(
        secondaryContainer,
        other.secondaryContainer,
        t,
      )!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceContainer: Color.lerp(
        surfaceContainer,
        other.surfaceContainer,
        t,
      )!,
      background: Color.lerp(background, other.background, t)!,
      error: Color.lerp(error, other.error, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      disabled: Color.lerp(disabled, other.disabled, t)!,
    );
  }
}
