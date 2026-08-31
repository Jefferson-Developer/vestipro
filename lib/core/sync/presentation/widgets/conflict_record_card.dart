import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../domain/entities/conflict_record.dart';
import '../presenters/conflict_presenter.dart';

/// One row of `ConflictListPage` (TASK-111): summarizes a single open
/// [ConflictRecord] — entity, when it was detected, how many fields diverge
/// — and links into `ConflictDetailPage` through [onTap]. Badges a
/// financial/critical conflict (`isCriticalConflict`) as "Crítico" with both
/// color and an icon/text label, never color alone (TASK-111's own
/// accessibility restriction).
class ConflictRecordCard extends StatelessWidget {
  const ConflictRecordCard({
    super.key,
    required this.record,
    required this.onTap,
  });

  final ConflictRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isCritical = isCriticalConflict(record);
    final fieldCount = record.conflictingFields.length;

    return Card(
      color: colors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.radius12),
        side: BorderSide(color: colors.outline.withValues(alpha: 0.3)),
      ),
      margin: const EdgeInsets.only(bottom: AppSpacing.spacing12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.radius12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spacing16),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          conflictEntityTypeLabel(record.entityType),
                          style: AppTypography.titleMedium.copyWith(
                            color: colors.onSurface,
                          ),
                        ),
                        if (isCritical) ...<Widget>[
                          const SizedBox(width: AppSpacing.spacing8),
                          const AppStatusBadge(
                            label: 'Crítico',
                            variant: AppStatusBadgeVariant.error,
                            icon: Icons.priority_high,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.spacing8),
                    Text(
                      'Detectado em ${conflictDetectedAtLabel(record.detectedAt)}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: colors.outline,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.spacing4),
                    Text(
                      fieldCount == 1
                          ? '1 campo divergente'
                          : '$fieldCount campos divergentes',
                      style: AppTypography.bodyMedium.copyWith(
                        color: colors.outline,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.spacing12),
              Icon(Icons.chevron_right, color: colors.outline),
            ],
          ),
        ),
      ),
    );
  }
}
