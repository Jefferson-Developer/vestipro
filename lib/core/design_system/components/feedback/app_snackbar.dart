import 'package:flutter/material.dart';

import '../../foundations/foundations.dart';
import '../../theme/theme.dart';

/// The semantic meaning an [AppSnackbar] communicates — always mapped to
/// the same color/icon pair across the app, same scale as
/// [AppStatusBadgeVariant].
enum AppSnackbarVariant { success, error, warning, info, neutral }

/// The single snackbar every feature must reuse for lightweight,
/// non-blocking feedback (e.g. "Rascunho salvo", "Sem conexão — pedido
/// salvo localmente").
///
/// Enqueues automatically when multiple calls happen in sequence: it is a
/// thin, token-driven wrapper around [ScaffoldMessenger.showSnackBar], which
/// already shows one [SnackBar] at a time and queues the rest — so two
/// [AppSnackbar.show] calls in a row never overlap or hide one another.
///
/// [AppSnackbar] is only for light confirmations. It must never be used as
/// the confirmation step for an irreversible action — use
/// [AppConfirmationDialog] instead.
abstract final class AppSnackbar {
  const AppSnackbar._();

  static const Duration _defaultDuration = Duration(seconds: 4);

  /// Shows [message], enqueuing behind any [AppSnackbar] already visible.
  static void show(
    BuildContext context, {
    required String message,
    AppSnackbarVariant variant = AppSnackbarVariant.neutral,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = _defaultDuration,
  }) {
    final colors = context.colors;
    final foreground = _foreground(colors, variant);
    final background = Color.alphaBlend(
      foreground.withValues(alpha: 0.16),
      colors.surfaceContainer,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radius8),
        ),
        content: Row(
          children: <Widget>[
            Icon(_icon(variant), size: AppIconSizes.md, color: foreground),
            const SizedBox(width: AppSpacing.spacing12),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodyMedium.copyWith(color: foreground),
              ),
            ),
          ],
        ),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: foreground,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  static IconData _icon(AppSnackbarVariant variant) => switch (variant) {
    AppSnackbarVariant.success => Icons.check_circle,
    AppSnackbarVariant.error => Icons.error,
    AppSnackbarVariant.warning => Icons.warning,
    AppSnackbarVariant.info => Icons.info,
    AppSnackbarVariant.neutral => Icons.circle_notifications,
  };

  static Color _foreground(AppColors colors, AppSnackbarVariant variant) =>
      switch (variant) {
        AppSnackbarVariant.success => colors.success,
        AppSnackbarVariant.error => colors.error,
        AppSnackbarVariant.warning => colors.warning,
        AppSnackbarVariant.info => colors.info,
        AppSnackbarVariant.neutral => colors.onSurface,
      };
}
