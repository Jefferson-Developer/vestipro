import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography tokens for the VestiPro Design System.
///
/// Scale: `displayLarge/Medium`, `headlineLarge/Medium`, `titleLarge/Medium`,
/// `bodyLarge/Medium/Small`, `labelLarge/Medium/Small`. No widget, page or
/// feature may hardcode a [TextStyle]/[TextTheme] outside of this file.
///
/// [fontFamily] is `Roboto`, the typeface the Flutter engine bundles and
/// guarantees on every platform (Android, iOS, Web, desktop) without any
/// extra font asset — so the Design System ships with a single, consistent
/// typeface everywhere out of the box. Every style below leaves `color`
/// unset; [textTheme] applies the right [AppColors.onSurface] for the
/// active theme, and every consumer keeps inheriting the platform/user text
/// scale via [MediaQuery.textScaler] because no style pins an absolute,
/// scale-independent size.
abstract final class AppTypography {
  const AppTypography._();

  static const String fontFamily = 'Roboto';

  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 57,
    height: 64 / 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 45,
    height: 52 / 45,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    height: 36 / 28,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    height: 16 / 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  /// Builds the [TextTheme] consumed by [ThemeData.textTheme], applying
  /// [AppColors.onSurface] from the active [colors] token set to every
  /// style above.
  static TextTheme textTheme(AppColors colors) {
    return TextTheme(
      displayLarge: displayLarge.copyWith(color: colors.onSurface),
      displayMedium: displayMedium.copyWith(color: colors.onSurface),
      headlineLarge: headlineLarge.copyWith(color: colors.onSurface),
      headlineMedium: headlineMedium.copyWith(color: colors.onSurface),
      titleLarge: titleLarge.copyWith(color: colors.onSurface),
      titleMedium: titleMedium.copyWith(color: colors.onSurface),
      bodyLarge: bodyLarge.copyWith(color: colors.onSurface),
      bodyMedium: bodyMedium.copyWith(color: colors.onSurface),
      bodySmall: bodySmall.copyWith(color: colors.onSurface),
      labelLarge: labelLarge.copyWith(color: colors.onSurface),
      labelMedium: labelMedium.copyWith(color: colors.onSurface),
      labelSmall: labelSmall.copyWith(color: colors.onSurface),
    );
  }
}
