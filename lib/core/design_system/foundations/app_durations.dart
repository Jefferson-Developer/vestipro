/// Animation duration tokens for the VestiPro Design System.
///
/// Kept short on purpose: `tasks.md` (seção 6) calls for "animações
/// discretas" and "transições suaves" — not showy motion. No widget, page
/// or feature may hardcode an [AnimationController]/`Duration` value for a
/// UI transition outside of this scale.
abstract final class AppDurations {
  const AppDurations._();

  /// Micro-interactions: icon/state toggles, ripple-adjacent feedback.
  static const Duration fast = Duration(milliseconds: 150);

  /// The default for most transitions: page elements, expand/collapse,
  /// dialogs, snackbars.
  static const Duration standard = Duration(milliseconds: 250);

  /// Larger surface changes: full-screen transitions, complex reordering.
  static const Duration slow = Duration(milliseconds: 400);
}
