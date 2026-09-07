import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/visit_route_stop.dart';

/// One ordered stop row of a built [VisitRoute] (TASK-177): position, name,
/// distance/eta estimate from the previous stop, progress action and the
/// "Navegar" action. Drag handle is provided by
/// `ReorderableListView.buildDefaultDragHandles` (same precedent as
/// `CategoriesPage`), not drawn here.
///
/// Progress has two distinct actions (TASK-178): a pending stop is only
/// ever completed through [onCheckIn] (the real check-in flow — evidence +
/// optional location + CRM timeline), while [onUndoCheckIn] only reverts an
/// already-completed stop back to pending (correcting a mistake), never
/// itself producing a check-in.
class VisitRouteStopTile extends StatelessWidget {
  const VisitRouteStopTile({
    required this.stop,
    required this.onCheckIn,
    required this.onUndoCheckIn,
    required this.onNavigate,
    super.key,
  });

  final VisitRouteStop stop;
  final VoidCallback onCheckIn;
  final VoidCallback onUndoCheckIn;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.radius8),
        border: Border.all(color: colors.outline.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 16,
            backgroundColor: stop.isCompleted ? colors.success : colors.primary,
            child: Text(
              '${stop.sequence + 1}',
              style: AppTypography.labelMedium.copyWith(
                color: colors.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  stop.displayName,
                  style: AppTypography.titleMedium.copyWith(
                    color: colors.onSurface,
                    decoration: stop.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing4),
                Text(
                  _distanceEtaLabel(stop),
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.outline,
                  ),
                ),
              ],
            ),
          ),
          AppIconButton(
            icon: Icons.navigation_outlined,
            semanticLabel: 'Navegar até ${stop.displayName}',
            onPressed: onNavigate,
          ),
          AppIconButton(
            icon: stop.isCompleted
                ? Icons.check_circle
                : Icons.check_circle_outline,
            semanticLabel: stop.isCompleted
                ? 'Desfazer check-in de ${stop.displayName}'
                : 'Fazer check-in em ${stop.displayName}',
            onPressed: stop.isCompleted ? onUndoCheckIn : onCheckIn,
          ),
        ],
      ),
    );
  }

  String _distanceEtaLabel(VisitRouteStop stop) {
    final distanceKm = stop.distanceFromPreviousKm;
    final etaMinutes = stop.etaMinutesFromPrevious;
    if (distanceKm == null || etaMinutes == null) {
      return 'Primeira parada';
    }
    return '${distanceKm.toStringAsFixed(1)} km · ~$etaMinutes min';
  }
}
