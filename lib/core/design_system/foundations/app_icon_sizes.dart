/// Icon size tokens for the VestiPro Design System.
///
/// The scale is aligned with [AppTypography] (icons pair with `label`/`body`
/// text at `sm`/`md`, with `titleLarge`/`headline` at `lg`/`xl`, and so on)
/// and with [AppSpacing] (each size is itself a value from the spacing
/// scale). No widget, page or feature may hardcode an icon `size` outside
/// of this file.
abstract final class AppIconSizes {
  const AppIconSizes._();

  /// Pairs with dense labels/captions (`labelSmall`/`labelMedium`).
  static const double sm = 16;

  /// The default icon size, pairing with `bodyMedium`/`labelLarge`.
  static const double md = 20;

  /// Pairs with `bodyLarge`/`titleMedium`; the most common standalone icon
  /// size (list leading icons, input adornments).
  static const double lg = 24;

  /// Pairs with `titleLarge`/`headlineMedium`; emphasis icons, empty states.
  static const double xl = 32;

  /// Pairs with `headlineLarge`/`displayMedium`; hero/illustration icons.
  static const double xxl = 40;

  /// The full scale, in ascending order, for enumeration in tests.
  static const List<double> scale = <double>[sm, md, lg, xl, xxl];
}
