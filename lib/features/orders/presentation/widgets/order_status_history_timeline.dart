import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/order_status_history_entry.dart';
import '../../domain/value_objects/order_status.dart';
import '../pages/order_list_page.dart'
    show OrderStatusBadge, orderStatusIcon, orderStatusLabel;

/// Read-only, chronological rendering of one Order's own
/// `Order.statusHistory` (TASK-104) — every entry [OrderStatusTransitionValidator]
/// already accepted and `Order.statusHistory` already carries, never
/// editable or removable from this widget (`tasks.md`'s own "histórico de
/// status é somente leitura" rule: there is no delete/edit affordance here
/// at all, by construction).
///
/// Reuses [AppTimeline] (the same component `CrmActivityTimeline` already
/// renders on) and [OrderStatusBadge]/[orderStatusLabel] (`OrderListPage`'s
/// own status mapping) instead of a second one, so a pedido's status always
/// reads the same everywhere in the app.
class OrderStatusHistoryTimeline extends StatelessWidget {
  const OrderStatusHistoryTimeline({
    required this.entries,
    this.emptyMessage = 'Nenhuma alteração de status registrada ainda.',
    super.key,
  });

  final List<OrderStatusHistoryEntry> entries;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return _TimelineEmpty(message: emptyMessage);
    }

    // `Order.statusHistory` is appended to (never reordered/rewritten), but
    // this widget sorts by `changedAt` explicitly rather than trust caller
    // order, so a chronological reading never depends on how the entry list
    // happened to be built upstream.
    final sorted = List<OrderStatusHistoryEntry>.of(entries)
      ..sort((a, b) => a.changedAt.compareTo(b.changedAt));

    return AppTimeline(
      entries: <AppTimelineEntry>[for (final entry in sorted) _entryFor(entry)],
    );
  }

  AppTimelineEntry _entryFor(OrderStatusHistoryEntry entry) {
    final previousStatus = entry.previousStatus;
    final title = previousStatus == null
        ? 'Pedido criado'
        : '${orderStatusLabel(previousStatus)} → '
              '${orderStatusLabel(entry.newStatus)}';
    final description = entry.reason?.trim().isNotEmpty ?? false
        ? entry.reason!.trim()
        : 'Sem motivo registrado para esta alteração.';

    return AppTimelineEntry(
      title: title,
      icon: orderStatusIcon(entry.newStatus),
      timestampLabel: _dateTimeLabel(entry.changedAt),
      description: description,
      isHighlighted: entry.newStatus == OrderStatus.rejected,
      semanticLabel: '$title, ${_dateTimeLabel(entry.changedAt)}',
      badges: <Widget>[
        OrderStatusBadge(status: entry.newStatus),
        AppStatusBadge(
          label: 'Por ${entry.actorId}',
          variant: AppStatusBadgeVariant.neutral,
          icon: Icons.person_outline,
        ),
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

String _dateTimeLabel(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} $hour:$minute';
}
