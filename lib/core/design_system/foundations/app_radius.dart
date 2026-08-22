/// Corner-radius tokens for the VestiPro Design System.
///
/// Scale: `4 8 12 16 20 24 full`. No widget, page or feature may hardcode a
/// [BorderRadius]/corner-radius value outside of this scale.
abstract final class AppRadius {
  const AppRadius._();

  static const double radius4 = 4;
  static const double radius8 = 8;
  static const double radius12 = 12;
  static const double radius16 = 16;
  static const double radius20 = 20;
  static const double radius24 = 24;

  /// Fully rounded ("pill"/circular) corners. Large enough to always be
  /// clamped by the shortest side of any real widget, regardless of size.
  static const double full = 999;

  /// The finite part of the scale, in ascending order, for enumeration in
  /// tests and in any tooling that needs to validate a value against the
  /// token set. [full] is intentionally excluded: it is not a fixed radius
  /// but a "round as much as the shape allows" token.
  static const List<double> scale = <double>[
    radius4,
    radius8,
    radius12,
    radius16,
    radius20,
    radius24,
  ];
}
