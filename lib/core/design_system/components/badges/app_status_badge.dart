import 'package:flutter/material.dart';

import '../../foundations/foundations.dart';
import '../../theme/theme.dart';

/// The semantic meaning a status badge communicates — order/client/sync
/// status, always mapped to the same color across the app.
enum AppStatusBadgeVariant { success, error, warning, info, neutral }

/// A small status pill (order status, client status, sync status, ...).
///
/// Meaning is never color-only: [label] text is mandatory, and an [icon] is
/// always rendered too (a sensible default per [variant] if the caller does
/// not pass one), so the badge stays legible for color-blind users and in
/// grayscale printouts/screenshots.
class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    required this.variant,
    this.icon,
  });

  final String label;
  final AppStatusBadgeVariant variant;

  /// Overrides the variant's default icon.
  final IconData? icon;

  IconData get _defaultIcon => switch (variant) {
    AppStatusBadgeVariant.success => Icons.check_circle,
    AppStatusBadgeVariant.error => Icons.error,
    AppStatusBadgeVariant.warning => Icons.warning,
    AppStatusBadgeVariant.info => Icons.info,
    AppStatusBadgeVariant.neutral => Icons.circle,
  };

  Color _foreground(AppColors colors) => switch (variant) {
    AppStatusBadgeVariant.success => colors.success,
    AppStatusBadgeVariant.error => colors.error,
    AppStatusBadgeVariant.warning => colors.warning,
    AppStatusBadgeVariant.info => colors.info,
    AppStatusBadgeVariant.neutral => colors.onSurface,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = _foreground(colors);
    final background = Color.alphaBlend(
      foreground.withValues(alpha: 0.16),
      colors.surface,
    );

    return Semantics(
      label: '$label: ${variant.name}',
      child: Container(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing12,
          vertical: AppSpacing.spacing4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon ?? _defaultIcon,
              size: AppIconSizes.sm,
              color: foreground,
            ),
            const SizedBox(width: AppSpacing.spacing8),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}
