import 'dart:math' as math;

import 'package:flutter/material.dart';

/// WCAG 2.x contrast ratio utilities (TASK-179, white-label catalog theming).
///
/// Extracted into a single shared implementation of
/// https://www.w3.org/TR/WCAG21/#dfn-contrast-ratio so both production code
/// (e.g. `AppBrandTheme`'s per-organization contrast fallback) and tests
/// (`app_colors_test.dart`) share one source of truth instead of each
/// re-deriving relative luminance independently.
abstract final class AppContrast {
  const AppContrast._();

  /// WCAG AA minimum contrast ratio for normal-weight body text.
  static const double wcagAaNormalText = 4.5;

  /// WCAG 2.x relative luminance of a single sRGB channel value in `[0, 1]`,
  /// per https://www.w3.org/TR/WCAG21/#dfn-relative-luminance.
  static double _channelLuminance(double channel) {
    return channel <= 0.03928
        ? channel / 12.92
        : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  }

  /// WCAG 2.x relative luminance of a [Color], per
  /// https://www.w3.org/TR/WCAG21/#dfn-relative-luminance. Public so callers
  /// that need to compare raw luminance directly (e.g. a `lerp` regression
  /// test) do not have to re-derive it.
  static double relativeLuminance(Color color) {
    final r = _channelLuminance((color.r * 255.0).round() / 255);
    final g = _channelLuminance((color.g * 255.0).round() / 255);
    final b = _channelLuminance((color.b * 255.0).round() / 255);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// WCAG 2.x contrast ratio between [a] and [b], per
  /// https://www.w3.org/TR/WCAG21/#dfn-contrast-ratio. Always >= 1.
  static double ratio(Color a, Color b) {
    final luminanceA = relativeLuminance(a);
    final luminanceB = relativeLuminance(b);
    final lighter = math.max(luminanceA, luminanceB);
    final darker = math.min(luminanceA, luminanceB);
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Whether [foreground] rendered over [background] meets
  /// [wcagAaNormalText].
  static bool meetsWcagAa(Color foreground, Color background) =>
      ratio(foreground, background) >= wcagAaNormalText;
}
