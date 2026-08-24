import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/crm_activity.dart';
import '../../domain/value_objects/crm_activity_sync_status.dart';
import '../../domain/value_objects/crm_activity_type.dart';

class CrmActivityTimeline extends StatelessWidget {
  const CrmActivityTimeline({
    required this.activities,
    this.overdueActivityIds = const <String>{},
    this.hasMore = false,
    this.isLoadingMore = false,
    this.onLoadMore,
    this.emptyMessage = 'Nenhuma atividade registrada ainda.',
    super.key,
  });

  final List<CrmActivity> activities;
  final Set<String> overdueActivityIds;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return _TimelineEmpty(message: emptyMessage);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppTimeline(
          entries: <AppTimelineEntry>[
            for (final activity in activities)
              _entryFor(
                activity,
                isOverdueFollowUp: overdueActivityIds.contains(activity.id),
              ),
          ],
        ),
        if (hasMore) ...<Widget>[
          const SizedBox(height: AppSpacing.spacing12),
          AppButton(
            label: 'Carregar mais',
            leadingIcon: Icons.expand_more,
            variant: AppButtonVariant.secondary,
            isLoading: isLoadingMore,
            onPressed: isLoadingMore ? null : onLoadMore,
          ),
        ],
      ],
    );
  }
}

class _TimelineEmpty extends StatelessWidget {
  const _TimelineEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.spacing12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppRadius.radius8),
        border: Border.all(color: colors.outline.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.event_note_outlined, color: colors.outline),
          const SizedBox(width: AppSpacing.spacing8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodyMedium.copyWith(color: colors.outline),
            ),
          ),
        ],
      ),
    );
  }
}

AppTimelineEntry _entryFor(
  CrmActivity activity, {
  required bool isOverdueFollowUp,
}) {
  return AppTimelineEntry(
    title: activity.type.label,
    icon: _iconFor(activity.type),
    timestampLabel: _dateTimeLabel(activity.occurredAt),
    description: activity.description,
    isHighlighted: isOverdueFollowUp,
    semanticLabel:
        '${activity.type.label}, ${activity.description}, '
        '${_dateTimeLabel(activity.occurredAt)}',
    badges: <Widget>[
      AppStatusBadge(
        label: 'Autor ${activity.userId}',
        variant: AppStatusBadgeVariant.neutral,
        icon: Icons.person_outline,
      ),
      if (activity.durationMinutes != null)
        AppStatusBadge(
          label: '${activity.durationMinutes} min',
          variant: AppStatusBadgeVariant.info,
          icon: Icons.timer_outlined,
        ),
      if (activity.syncStatus != CrmActivitySyncStatus.synced)
        AppStatusBadge(
          label: _syncLabel(activity.syncStatus),
          variant: AppStatusBadgeVariant.warning,
          icon: Icons.cloud_queue,
        ),
      if (isOverdueFollowUp)
        const AppStatusBadge(
          label: 'Follow-up vencido',
          variant: AppStatusBadgeVariant.warning,
          icon: Icons.schedule,
        ),
    ],
  );
}

IconData _iconFor(CrmActivityType type) {
  return switch (type) {
    CrmActivityType.phoneCall => Icons.call_outlined,
    CrmActivityType.visit => Icons.storefront_outlined,
    CrmActivityType.meeting => Icons.groups_outlined,
    CrmActivityType.message => Icons.chat_bubble_outline,
    CrmActivityType.note => Icons.sticky_note_2_outlined,
  };
}

String _syncLabel(CrmActivitySyncStatus status) {
  return switch (status) {
    CrmActivitySyncStatus.pending => 'Pendente de sync',
    CrmActivitySyncStatus.syncing => 'Sincronizando',
    CrmActivitySyncStatus.synced => 'Sincronizado',
    CrmActivitySyncStatus.failed => 'Sync falhou',
    CrmActivitySyncStatus.conflict => 'Conflito de sync',
  };
}

String _dateTimeLabel(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} $hour:$minute';
}
