import 'package:flutter/material.dart';

import '../../foundations/foundations.dart';
import '../../theme/theme.dart';
import '../buttons/app_button.dart';

/// The generic error state, reused whenever a list/screen fails to load.
///
/// [message] must always be a friendly, already-translated string decided
/// by the caller — this widget never renders a raw
/// exception/stack-trace/technical error to the end user. [retryLabel] is
/// required whenever [onRetry] is set, so the action never ships without a
/// caller-provided (i18n-ready) label.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.error_outline,
    this.retryLabel,
    this.onRetry,
  }) : assert(
         onRetry == null || retryLabel != null,
         'retryLabel is required whenever onRetry is provided.',
       );

  final String title;
  final String message;
  final IconData icon;
  final String? retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: AppIconSizes.xxl, color: colors.error),
            const SizedBox(height: AppSpacing.spacing16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: colors.outline),
            ),
            if (retryLabel != null && onRetry != null) ...<Widget>[
              const SizedBox(height: AppSpacing.spacing24),
              AppButton(
                label: retryLabel!,
                onPressed: onRetry,
                variant: AppButtonVariant.secondary,
                leadingIcon: Icons.refresh,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
