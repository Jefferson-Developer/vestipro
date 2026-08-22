/// Responsive layout primitives every screen composes around: the central
/// breakpoint-resolution widget ([AppResponsiveBuilder]), the adaptive
/// navigation shell ([AppAdaptiveShell] — bottom navigation on mobile, a
/// rail on tablet, a permanent collapsible sidebar on desktop/large
/// desktop) and the standard administrative page skeleton
/// ([AppAdminPageLayout] — header + content + filters, side panel on
/// desktop or a bottom sheet on mobile/tablet).
///
/// No feature may build its own `LayoutBuilder`/`MediaQuery`-driven
/// breakpoint switch, its own mobile-vs-desktop navigation shell, or a
/// bespoke mobile-only/desktop-only admin page skeleton — reuse what is
/// exported here instead. See `README.md` in this folder for the guide on
/// when to target each [AppBreakpoint] tier.
///
/// Exported from the `design_system.dart` barrel; features must not import
/// a file inside `layouts/` directly.
library;

export 'app_adaptive_shell.dart';
export 'app_admin_page_layout.dart';
export 'app_nav_destination.dart';
export 'app_responsive_builder.dart';
