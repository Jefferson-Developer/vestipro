/// The resolved layout tier for a given available width. See
/// [AppBreakpoints.resolve].
enum AppBreakpoint { mobile, tablet, desktop, largeDesktop }

/// Responsive breakpoint tokens for the VestiPro Design System.
///
/// Widths are the lower bound (inclusive) of each tier. No widget, page or
/// feature may hardcode a layout-width threshold outside of this file —
/// always resolve through [AppBreakpoints.resolve] (or the
/// `context.breakpoint` convenience getter in `design_system_context.dart`).
abstract final class AppBreakpoints {
  const AppBreakpoints._();

  /// Smartphones in portrait or landscape.
  static const double mobile = 0;

  /// Tablets and small foldables.
  static const double tablet = 600;

  /// Small/medium laptop and desktop windows.
  static const double desktop = 1024;

  /// Wide desktop monitors and maximized web windows.
  static const double largeDesktop = 1440;

  /// Resolves the [AppBreakpoint] tier for the given available [width]
  /// (typically `MediaQuery.sizeOf(context).width`).
  static AppBreakpoint resolve(double width) {
    if (width >= largeDesktop) {
      return AppBreakpoint.largeDesktop;
    }
    if (width >= desktop) {
      return AppBreakpoint.desktop;
    }
    if (width >= tablet) {
      return AppBreakpoint.tablet;
    }
    return AppBreakpoint.mobile;
  }
}
