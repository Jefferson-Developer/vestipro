import 'package:flutter/material.dart';

/// Elevation/shadow tokens for the VestiPro Design System.
///
/// [light] and [dark] provide four consistent elevation levels (`sm`, `md`,
/// `lg`, `xl`). Dark-mode shadows deliberately carry *more* opacity than
/// their light-mode counterparts — a shadow with light-mode opacity would be
/// nearly invisible against a dark surface, so elevation would silently stop
/// communicating depth in dark mode. No widget, page or feature may
/// hardcode a [BoxShadow] outside of this file.
@immutable
class AppShadows {
  const AppShadows({
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
  });

  final List<BoxShadow> sm;
  final List<BoxShadow> md;
  final List<BoxShadow> lg;
  final List<BoxShadow> xl;

  static const AppShadows light = AppShadows(
    sm: <BoxShadow>[
      BoxShadow(color: Color(0x1F000000), blurRadius: 4, offset: Offset(0, 1)),
    ],
    md: <BoxShadow>[
      BoxShadow(color: Color(0x24000000), blurRadius: 8, offset: Offset(0, 2)),
    ],
    lg: <BoxShadow>[
      BoxShadow(color: Color(0x29000000), blurRadius: 16, offset: Offset(0, 4)),
    ],
    xl: <BoxShadow>[
      BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 8)),
    ],
  );

  static const AppShadows dark = AppShadows(
    sm: <BoxShadow>[
      BoxShadow(color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 1)),
    ],
    md: <BoxShadow>[
      BoxShadow(color: Color(0x80000000), blurRadius: 8, offset: Offset(0, 2)),
    ],
    lg: <BoxShadow>[
      BoxShadow(color: Color(0x8C000000), blurRadius: 16, offset: Offset(0, 4)),
    ],
    xl: <BoxShadow>[
      BoxShadow(color: Color(0x99000000), blurRadius: 24, offset: Offset(0, 8)),
    ],
  );

  /// Resolves the correct elevation set for the given [brightness], so
  /// callers never have to branch on `Brightness.dark` themselves.
  static AppShadows resolve(Brightness brightness) {
    return brightness == Brightness.dark ? dark : light;
  }
}
