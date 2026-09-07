import 'package:flutter/material.dart';

import '../foundations/foundations.dart';
import 'app_theme.dart';

/// Derives a per-organization branded [AppColors]/[ThemeData] (TASK-179,
/// catálogo white-label) from `OrganizationSettings.brandingPrimaryColorHex`
/// — always applied *on top of* the same Design System tokens/components the
/// rest of the catalog already renders with (`AppProductGrid`/`AppProductCard`
/// and friends), never a second widget tree per organization.
///
/// Accessibility always wins: a malformed custom color is discarded outright
/// (the Design System's own default primary/onPrimary pair is used
/// untouched), and a *valid* custom color that cannot pair with the theme's
/// preferred `onPrimary` at WCAG AA (>= [AppContrast.wcagAaNormalText])
/// automatically swaps in a plain white/black text color instead — see
/// [resolveColors]/[needsContrastFallback]. Configuration itself lives
/// exclusively in each organization's own
/// `OrganizationSettings` (Firestore-scoped per tenant, TASK-026/037), so
/// this resolver never has a way to read — let alone apply — another
/// organization's color: it only ever transforms whatever hex string its
/// caller already resolved for the *current* organization/share.
abstract final class AppBrandTheme {
  const AppBrandTheme._();

  /// `#RRGGBB` hex color pattern — mirrors `OrganizationSettings`'s own
  /// validation pattern, duplicated here (not imported) so this Design
  /// System layer never depends on a feature.
  static final RegExp _hexColorPattern = RegExp(r'^#([0-9A-Fa-f]{6})$');

  /// Builds the branded [AppColors] for [base] (typically [AppColors.light]
  /// or [AppColors.dark]) given an optional `#RRGGBB` [primaryColorHex].
  /// Returns [base] unchanged when [primaryColorHex] is `null`/blank/
  /// malformed; otherwise applies the custom [primaryColorHex] as `primary`
  /// with whichever readable `onPrimary` text color meets WCAG AA against it
  /// (see [_resolveOnPrimary]) — the safe fallback TASK-179 requires.
  static AppColors resolveColors({
    required AppColors base,
    String? primaryColorHex,
  }) {
    final parsedPrimary = _parseHexColor(primaryColorHex);
    if (parsedPrimary == null) return base;

    final onPrimary = _resolveOnPrimary(parsedPrimary, base.onPrimary);
    return base.copyWith(primary: parsedPrimary, onPrimary: onPrimary);
  }

  /// Whether [primaryColorHex] is configured but a fallback had to kick in
  /// to keep it accessible: either the hex itself is malformed (the whole
  /// custom color is discarded, [base] is used untouched) or it parsed fine
  /// but its natural/preferred on-color ([base]'s own `onPrimary`) fails
  /// WCAG AA against it, forcing [resolveColors] to swap in a plain
  /// white/black instead — the signal a brand configuration screen uses to
  /// warn "a cor definida não atinge o contraste mínimo; um ajuste
  /// automático foi aplicado" instead of silently ignoring what the
  /// organization typed. `false` when [primaryColorHex] is not configured
  /// (`null`/blank) or applies with no adjustment at all.
  static bool needsContrastFallback({
    required AppColors base,
    String? primaryColorHex,
  }) {
    final trimmed = primaryColorHex?.trim();
    if (trimmed == null || trimmed.isEmpty) return false;

    final parsedPrimary = _parseHexColor(trimmed);
    if (parsedPrimary == null) return true;
    return _resolveOnPrimary(parsedPrimary, base.onPrimary) != base.onPrimary;
  }

  /// Builds the full branded [ThemeData] for [brightness], reusing
  /// [AppTheme.fromColors] — the exact same assembly [AppTheme.light]/
  /// [AppTheme.dark] use.
  static ThemeData resolveTheme({
    required Brightness brightness,
    String? primaryColorHex,
  }) {
    final base = brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final colors = resolveColors(base: base, primaryColorHex: primaryColorHex);
    return AppTheme.fromColors(colors, brightness);
  }

  static Color? _parseHexColor(String? hex) {
    final trimmed = hex?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    if (!_hexColorPattern.hasMatch(trimmed)) return null;
    final value = int.parse(trimmed.substring(1), radix: 16);
    return Color(0xFF000000 | value);
  }

  /// Picks the first of [preferred] (the base theme's own `onPrimary`),
  /// pure white or pure black that meets WCAG AA against [background] — the
  /// same 3-candidate fallback order a Material color scheme would use. At
  /// least one of white/black mathematically always meets
  /// [AppContrast.wcagAaNormalText] against any background (their
  /// contrast-ratio ranges overlap across the full luminance spectrum), so
  /// this never has to give up on returning *some* readable color; the
  /// final tie-break only exists as a defensive fallback, never expected to
  /// run in practice.
  static Color _resolveOnPrimary(Color background, Color preferred) {
    if (AppContrast.meetsWcagAa(preferred, background)) return preferred;
    if (AppContrast.meetsWcagAa(Colors.white, background)) return Colors.white;
    if (AppContrast.meetsWcagAa(Colors.black, background)) return Colors.black;
    return AppContrast.ratio(Colors.white, background) >=
            AppContrast.ratio(Colors.black, background)
        ? Colors.white
        : Colors.black;
  }
}
