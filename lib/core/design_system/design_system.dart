/// The VestiPro Design System: single import for every color, spacing,
/// radius, shadow, typography, breakpoint, duration and icon-size token,
/// plus the assembled light/dark [ThemeData] (`AppTheme`) and the
/// `context.colors`/`context.shadows`/`context.breakpoint` convenience
/// getters.
///
/// This is the only supported entry point: features must import
/// `package:vestipro/core/design_system/design_system.dart`, never a file
/// inside `foundations/`/`theme/` directly.
library;

export 'foundations/foundations.dart';
export 'theme/theme.dart';
