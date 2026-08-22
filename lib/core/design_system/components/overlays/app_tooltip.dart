import 'package:flutter/material.dart';

import '../../foundations/foundations.dart';
import '../../theme/theme.dart';

/// The tooltip every feature must reuse for complementary/help text
/// attached to an icon, label or truncated value.
///
/// Shows on hover (mouse, desktop/Web) and, since Flutter's [Tooltip] falls
/// back to a long-press trigger on touch devices by default, stays
/// reachable on mobile too without any extra wiring.
///
/// [AppTooltip] must never be the *only* channel for essential commercial
/// information (price, stock, condition, restriction) — those must always
/// be visible in the surrounding UI; the tooltip only adds context.
///
/// ```dart
/// AppTooltip(
///   message: 'Preço sujeito à tabela vigente do cliente',
///   child: Icon(Icons.info_outline),
/// )
/// ```
class AppTooltip extends StatelessWidget {
  const AppTooltip({
    super.key,
    required this.message,
    required this.child,
    this.waitDuration = AppDurations.standard,
    this.triggerMode,
  });

  /// A standalone "help" affordance: a small info icon that only exists to
  /// carry [message], for places with no other widget to attach the tooltip
  /// to (e.g. next to a form field's label).
  static Widget helpIcon({Key? key, required String message}) {
    return AppTooltip(
      key: key,
      message: message,
      child: Builder(
        builder: (context) => Icon(
          Icons.help_outline,
          size: AppIconSizes.sm,
          color: context.colors.outline,
        ),
      ),
    );
  }

  final String message;
  final Widget child;

  /// How long the pointer must hover before the tooltip appears on
  /// desktop/Web. Ignored on the long-press (touch) trigger.
  final Duration waitDuration;

  /// Overrides the default trigger (hover on desktop/Web, long-press on
  /// touch devices). Left `null` in the vast majority of call sites.
  final TooltipTriggerMode? triggerMode;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Tooltip(
      message: message,
      waitDuration: waitDuration,
      triggerMode: triggerMode,
      decoration: BoxDecoration(
        color: colors.onSurface,
        borderRadius: BorderRadius.circular(AppRadius.radius8),
      ),
      textStyle: AppTypography.bodySmall.copyWith(color: colors.surface),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing12,
        vertical: AppSpacing.spacing8,
      ),
      child: child,
    );
  }
}
