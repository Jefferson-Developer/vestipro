import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/order_submission_issue.dart';
import '../bloc/order_submission_validation_cubit.dart';
import '../bloc/order_submission_validation_state.dart';

/// "Antes de enviar, resolva:" panel (EPIC-13, TASK-100): every
/// `OrderSubmissionIssue` `OrderSubmissionValidationCubit` currently reports,
/// blocking pendencies first (never hidden, never silently merged with
/// avisos) and non-blocking avisos below — each one tappable straight to the
/// part of the order that needs the fix ([onIssueTap]), matching TASK-100's
/// "cada item levando diretamente ao ponto do pedido que precisa de ajuste"
/// requirement. Renders nothing while there is nothing to show, exactly like
/// `OrderPricingSummarySection`'s own "nothing to show yet" precedent.
class OrderSubmissionPendenciesPanel extends StatelessWidget {
  const OrderSubmissionPendenciesPanel({this.onIssueTap, super.key});

  final void Function(OrderSubmissionIssue issue)? onIssueTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      OrderSubmissionValidationCubit,
      OrderSubmissionValidationState
    >(
      builder: (context, state) {
        if (!state.hasPendencies) return const SizedBox.shrink();
        final colors = context.colors;
        final blocking = state.blockingIssues;
        final warnings = state.warnings;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.spacing16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.radius8),
            border: Border.all(
              color: (blocking.isNotEmpty ? colors.error : colors.warning)
                  .withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (blocking.isNotEmpty) ...<Widget>[
                Text(
                  'Antes de enviar, resolva:',
                  style: AppTypography.titleMedium.copyWith(
                    color: colors.error,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing8),
                for (final issue in blocking)
                  _OrderSubmissionIssueRow(
                    issue: issue,
                    color: colors.error,
                    icon: Icons.error_outline,
                    onTap: onIssueTap == null ? null : () => onIssueTap!(issue),
                  ),
              ],
              if (warnings.isNotEmpty) ...<Widget>[
                if (blocking.isNotEmpty)
                  const SizedBox(height: AppSpacing.spacing12),
                Text(
                  'Avisos',
                  style: AppTypography.titleMedium.copyWith(
                    color: colors.warning,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing8),
                for (final issue in warnings)
                  _OrderSubmissionIssueRow(
                    issue: issue,
                    color: colors.warning,
                    icon: Icons.warning_amber_outlined,
                    onTap: onIssueTap == null ? null : () => onIssueTap!(issue),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _OrderSubmissionIssueRow extends StatelessWidget {
  const _OrderSubmissionIssueRow({
    required this.issue,
    required this.color,
    required this.icon,
    this.onTap,
  });

  final OrderSubmissionIssue issue;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final prefix = issue.isBlocking ? 'Pendência' : 'Aviso';
    return Semantics(
      label: '$prefix: ${issue.message}',
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.radius8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppSpacing.spacing8),
              Expanded(
                child: Text(
                  issue.message,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right, color: colors.outline, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
