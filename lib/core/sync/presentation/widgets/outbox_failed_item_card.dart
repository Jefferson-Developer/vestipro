import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../domain/entities/outbox_operation.dart';
import '../presenters/sync_center_presenter.dart';

/// One row of the Central de Sincronização's (TASK-112, EPIC-14) failure
/// list: the entity affected, a business-friendly message
/// ([syncFailureMessageLabel] — never [OutboxOperation.lastError] itself)
/// and its own "Tentar novamente" action, independent of every other row's.
class OutboxFailedItemCard extends StatelessWidget {
  const OutboxFailedItemCard({
    super.key,
    required this.operation,
    required this.isRetrying,
    required this.isRetryEnabled,
    required this.onRetry,
  });

  final OutboxOperation operation;

  /// Whether this specific row's retry is in flight — only this row shows a
  /// loading button, every other row stays interactive.
  final bool isRetrying;

  /// `false` while offline or while "Sincronizar agora"/"Tentar novamente
  /// todos" is running for the whole screen.
  final bool isRetryEnabled;

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Card(
      color: colors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.radius12),
        side: BorderSide(color: colors.outline.withValues(alpha: 0.3)),
      ),
      margin: const EdgeInsets.only(bottom: AppSpacing.spacing12),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.error_outline, color: colors.error),
            const SizedBox(width: AppSpacing.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    syncFailureMessageLabel(operation),
                    style: AppTypography.bodyMedium.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                  if (operation.lastAttemptAt != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.spacing4),
                    Text(
                      'Última tentativa em '
                      '${syncDateTimeLabel(operation.lastAttemptAt!)}',
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.outline,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.spacing12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AppButton(
                      label: 'Tentar novamente',
                      variant: AppButtonVariant.secondary,
                      leadingIcon: Icons.refresh,
                      isLoading: isRetrying,
                      isDisabled: !isRetryEnabled,
                      onPressed: onRetry,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
