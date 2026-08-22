/// Spacing tokens for the VestiPro Design System.
///
/// Base-4 scale: `4 8 12 16 20 24 32 40 48 64`. No widget, page or feature
/// may hardcode a spacing/padding/gap value outside of this scale.
abstract final class AppSpacing {
  const AppSpacing._();

  static const double spacing4 = 4;
  static const double spacing8 = 8;
  static const double spacing12 = 12;
  static const double spacing16 = 16;
  static const double spacing20 = 20;
  static const double spacing24 = 24;
  static const double spacing32 = 32;
  static const double spacing40 = 40;
  static const double spacing48 = 48;
  static const double spacing64 = 64;

  /// The full scale, in ascending order, for enumeration in tests and in
  /// any tooling that needs to validate a value against the token set.
  static const List<double> scale = <double>[
    spacing4,
    spacing8,
    spacing12,
    spacing16,
    spacing20,
    spacing24,
    spacing32,
    spacing40,
    spacing48,
    spacing64,
  ];
}
