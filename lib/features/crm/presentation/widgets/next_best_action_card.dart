import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/next_best_action.dart';
import '../../domain/value_objects/next_best_action_priority.dart';
import '../../domain/value_objects/next_best_action_type.dart';

class NextBestActionCard extends StatelessWidget {
  const NextBestActionCard({
    required this.action,
    required this.onPressed,
    this.showCustomerName = false,
    super.key,
  });

  final NextBestAction action;
  final VoidCallback? onPressed;
  final bool showCustomerName;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      key: Key('next-best-action-card-${action.id}'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.radius8),
        border: Border.all(color: colors.outline.withValues(alpha: 0.18)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          final body = _NextBestActionBody(
            action: action,
            showCustomerName: showCustomerName,
            compact: compact,
          );
          final button = AppButton(
            label: _buttonLabel(action.type, compact: compact),
            leadingIcon: _buttonIcon(action.type),
            variant: AppButtonVariant.secondary,
            expand: compact,
            onPressed: onPressed,
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                body,
                const SizedBox(height: AppSpacing.spacing12),
                button,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: body),
              const SizedBox(width: AppSpacing.spacing16),
              button,
            ],
          );
        },
      ),
    );
  }

  static String _buttonLabel(NextBestActionType type, {required bool compact}) {
    if (compact) {
      return switch (type) {
        NextBestActionType.callCustomer => 'Ligar',
        NextBestActionType.scheduleVisit => 'Visita',
        NextBestActionType.completeOrRescheduleFollowUp => 'Follow-up',
      };
    }
    return switch (type) {
      NextBestActionType.callCustomer => 'Registrar ligacao',
      NextBestActionType.scheduleVisit => 'Registrar visita',
      NextBestActionType.completeOrRescheduleFollowUp => 'Resolver follow-up',
    };
  }

  static IconData _buttonIcon(NextBestActionType type) {
    return switch (type) {
      NextBestActionType.callCustomer => Icons.call_outlined,
      NextBestActionType.scheduleVisit => Icons.location_on_outlined,
      NextBestActionType.completeOrRescheduleFollowUp =>
        Icons.task_alt_outlined,
    };
  }
}

class _NextBestActionBody extends StatelessWidget {
  const _NextBestActionBody({
    required this.action,
    required this.showCustomerName,
    required this.compact,
  });

  final NextBestAction action;
  final bool showCustomerName;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: AppSpacing.spacing40,
          height: AppSpacing.spacing40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              colors.primary.withValues(alpha: 0.12),
              colors.surface,
            ),
            borderRadius: BorderRadius.circular(AppRadius.radius8),
          ),
          child: Icon(
            _actionIcon(action.type),
            color: colors.primary,
            size: AppIconSizes.md,
          ),
        ),
        const SizedBox(width: AppSpacing.spacing12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: AppSpacing.spacing8,
                runSpacing: AppSpacing.spacing8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  AppStatusBadge(
                    label: _priorityLabel(action.priority, compact: compact),
                    variant: _priorityVariant(action.priority),
                    icon: Icons.flag_outlined,
                  ),
                  if (showCustomerName)
                    AppStatusBadge(
                      label: action.customerName,
                      variant: AppStatusBadgeVariant.neutral,
                      icon: Icons.storefront_outlined,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.spacing8),
              Text(
                action.suggestedAction,
                style: AppTypography.titleMedium.copyWith(
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.spacing4),
              Text(
                action.reason,
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.spacing4),
              Text(
                action.evidence,
                style: AppTypography.bodySmall.copyWith(color: colors.outline),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static IconData _actionIcon(NextBestActionType type) {
    return switch (type) {
      NextBestActionType.callCustomer => Icons.call_outlined,
      NextBestActionType.scheduleVisit => Icons.route_outlined,
      NextBestActionType.completeOrRescheduleFollowUp =>
        Icons.event_available_outlined,
    };
  }

  static String _priorityLabel(
    NextBestActionPriority priority, {
    required bool compact,
  }) {
    if (compact) {
      return switch (priority) {
        NextBestActionPriority.high => 'Alta',
        NextBestActionPriority.medium => 'Media',
        NextBestActionPriority.low => 'Baixa',
      };
    }
    return switch (priority) {
      NextBestActionPriority.high => 'Alta prioridade',
      NextBestActionPriority.medium => 'Prioridade media',
      NextBestActionPriority.low => 'Baixa prioridade',
    };
  }

  static AppStatusBadgeVariant _priorityVariant(
    NextBestActionPriority priority,
  ) {
    return switch (priority) {
      NextBestActionPriority.high => AppStatusBadgeVariant.warning,
      NextBestActionPriority.medium => AppStatusBadgeVariant.info,
      NextBestActionPriority.low => AppStatusBadgeVariant.neutral,
    };
  }
}

class RepresentativeNextBestActionSection extends StatelessWidget {
  const RepresentativeNextBestActionSection({
    required this.actions,
    required this.onActionPressed,
    super.key,
  });

  final List<NextBestAction> actions;
  final ValueChanged<NextBestAction> onActionPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(Icons.auto_awesome_outlined, color: colors.primary),
            const SizedBox(width: AppSpacing.spacing8),
            Expanded(
              child: Text(
                'Proximas melhores acoes',
                style: AppTypography.titleMedium.copyWith(
                  color: colors.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.spacing12),
        if (actions.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.spacing12),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(AppRadius.radius8),
              border: Border.all(color: colors.outline.withValues(alpha: 0.18)),
            ),
            child: Text(
              'Nenhuma recomendacao prioritaria agora.',
              style: AppTypography.bodyMedium.copyWith(color: colors.outline),
            ),
          )
        else
          for (final action in actions)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.spacing8),
              child: NextBestActionCard(
                action: action,
                showCustomerName: true,
                onPressed: () => onActionPressed(action),
              ),
            ),
      ],
    );
  }
}
