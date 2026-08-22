import 'package:flutter/material.dart';

import '../foundations/foundations.dart';

/// The single entry point components and screens use to read Design System
/// tokens: `context.colors`, `context.shadows` and `context.breakpoint`
/// resolve against the *active* theme/window size, so nothing has to branch
/// on `Theme.of(context).brightness`/`MediaQuery` by hand.
///
/// Tokens that never vary with the active theme (spacing, radius,
/// typography, durations, icon sizes) are read directly from their
/// foundation class (e.g. `AppSpacing.spacing16`), which is exported from
/// this same `design_system.dart` barrel.
extension DesignSystemContext on BuildContext {
  /// The semantic color tokens for the active theme (light/dark). Falls
  /// back to [AppColors.light] if [AppTheme] was somehow not wired into
  /// `MaterialApp.theme`/`darkTheme`, so a missing extension never crashes
  /// the app — it just silently loses dark-mode awareness for that read.
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;

  /// The elevation tokens matching the active theme's brightness.
  AppShadows get shadows => AppShadows.resolve(Theme.of(this).brightness);

  /// The responsive tier for the current available width.
  AppBreakpoint get breakpoint =>
      AppBreakpoints.resolve(MediaQuery.sizeOf(this).width);
}
