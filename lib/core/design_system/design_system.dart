/// The VestiPro Design System: single import for every color, spacing,
/// radius, shadow, typography, breakpoint, duration and icon-size token,
/// the assembled light/dark [ThemeData] (`AppTheme`), the
/// `context.colors`/`context.shadows`/`context.breakpoint` convenience
/// getters, every reusable component (buttons, inputs, selection, chips,
/// badges, feedback states) and the responsive layout primitives
/// (`AppResponsiveBuilder`, `AppAdaptiveShell`, `AppAdminPageLayout`).
///
/// This is the only supported entry point: features must import
/// `package:vestipro/core/design_system/design_system.dart`, never a file
/// inside `foundations/`/`theme/`/`components/`/`layouts/` directly.
library;

export 'components/components.dart';
export 'foundations/foundations.dart';
export 'layouts/layouts.dart';
export 'theme/theme.dart';
