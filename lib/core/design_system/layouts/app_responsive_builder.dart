import 'package:flutter/widgets.dart';

import '../foundations/foundations.dart';

/// The single, central way any Design System widget, page or feature
/// resolves a responsive [AppBreakpoint] for *its own available width* —
/// never the full device/window width read ad hoc via
/// `MediaQuery.of(context).size.width`.
///
/// [AppResponsiveBuilder] wraps a [LayoutBuilder] and resolves
/// [AppBreakpoints.resolve] against `constraints.maxWidth`, so nesting it
/// inside a sidebar, a card or a bottom sheet always reflects the space
/// that widget actually has — not the whole screen. When a widget genuinely
/// needs the *window*-level tier instead (e.g. deciding the top-level
/// navigation shell), use the `context.breakpoint` convenience getter from
/// `design_system_context.dart`, which reads `MediaQuery.sizeOf` on
/// purpose; every other case should prefer this widget.
///
/// ```dart
/// AppResponsiveBuilder(
///   builder: (context, breakpoint) => switch (breakpoint) {
///     AppBreakpoint.mobile => const _MobileFilters(),
///     _ => const _DesktopFilters(),
///   },
/// )
/// ```
class AppResponsiveBuilder extends StatelessWidget {
  const AppResponsiveBuilder({super.key, required this.builder});

  /// Builds the widget tree for the resolved [AppBreakpoint]. Called again
  /// automatically whenever the available width crosses into a different
  /// tier (window resize on Web/desktop, orientation change, a parent
  /// panel collapsing/expanding).
  final Widget Function(BuildContext context, AppBreakpoint breakpoint) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final breakpoint = AppBreakpoints.resolve(constraints.maxWidth);
        return builder(context, breakpoint);
      },
    );
  }
}

/// A value that varies per [AppBreakpoint], with each tier above [mobile]
/// falling back to the next narrower tier that was actually provided.
///
/// Meant to replace the scattered
/// `breakpoint == AppBreakpoint.mobile ? a : (breakpoint == AppBreakpoint.desktop ? b : c)`
/// conditionals that would otherwise be duplicated across screens — every
/// caller instead declares the value once per tier that matters and calls
/// [resolve].
///
/// ```dart
/// const columns = AppResponsiveValue<int>(mobile: 1, tablet: 2, desktop: 3);
/// final crossAxisCount = columns.resolve(breakpoint);
/// ```
@immutable
class AppResponsiveValue<T> {
  const AppResponsiveValue({
    required this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });

  /// The baseline value, required because every screen must render
  /// something on the narrowest supported tier.
  final T mobile;

  /// Falls back to [mobile] when not provided.
  final T? tablet;

  /// Falls back to [tablet], then [mobile], when not provided.
  final T? desktop;

  /// Falls back to [desktop], then [tablet], then [mobile], when not
  /// provided.
  final T? largeDesktop;

  /// Resolves the value for [breakpoint], applying the narrower-tier
  /// fallback chain documented on each field above.
  T resolve(AppBreakpoint breakpoint) {
    switch (breakpoint) {
      case AppBreakpoint.mobile:
        return mobile;
      case AppBreakpoint.tablet:
        return tablet ?? mobile;
      case AppBreakpoint.desktop:
        return desktop ?? tablet ?? mobile;
      case AppBreakpoint.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
    }
  }
}
