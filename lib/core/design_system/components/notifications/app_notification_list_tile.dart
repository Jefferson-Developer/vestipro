import 'package:flutter/material.dart';

import '../../foundations/foundations.dart';
import '../../theme/theme.dart';
import '../badges/app_status_badge.dart';

/// The three groupings [AppNotificationListTile] renders an icon/color for —
/// mirrors `AppNotificationCategory` (`lib/core/notifications/`) without
/// this design-system component depending on that domain enum directly.
enum AppNotificationTileCategory { crm, commercial, system }

/// One row of the central de notificações internas (TASK-151): a
/// category icon, title, short body preview, a relative/absolute timestamp
/// and an unread indicator.
///
/// The unread state is never color-only (accessibility): an unread
/// notification renders a filled dot *and* a bold title, on top of the
/// (also non-exclusive) tinted background — so it stays legible for
/// color-blind users and in a grayscale screenshot.
class AppNotificationListTile extends StatelessWidget {
  const AppNotificationListTile({
    super.key,
    required this.title,
    required this.body,
    required this.category,
    required this.timestampLabel,
    required this.isUnread,
    this.isCritical = false,
    this.onTap,
  });

  final String title;
  final String body;
  final AppNotificationTileCategory category;
  final String timestampLabel;
  final bool isUnread;

  /// Whether this notification is high-priority (TASK-153) — e.g. meta em
  /// risco alto, pedido rejeitado, falha crítica de sincronização. Never
  /// signaled by color alone: a critical notification renders an
  /// [AppStatusBadge] with both an icon and the "Crítico" label, on top of
  /// (never instead of) its [category] color, so it stays legible for
  /// color-blind users and in a grayscale screenshot — same accessibility
  /// contract [isUnread] already sets for this tile.
  final bool isCritical;
  final VoidCallback? onTap;

  IconData get _categoryIcon => switch (category) {
    AppNotificationTileCategory.crm => Icons.support_agent,
    AppNotificationTileCategory.commercial => Icons.trending_up,
    AppNotificationTileCategory.system => Icons.settings_outlined,
  };

  String get _categoryLabel => switch (category) {
    AppNotificationTileCategory.crm => 'CRM',
    AppNotificationTileCategory.commercial => 'Comercial',
    AppNotificationTileCategory.system => 'Sistema',
  };

  Color _categoryColor(AppColors colors) => switch (category) {
    AppNotificationTileCategory.crm => colors.info,
    AppNotificationTileCategory.commercial => colors.primary,
    AppNotificationTileCategory.system => colors.outline,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final categoryColor = _categoryColor(colors);
    final semanticStatus = isUnread ? 'não lida' : 'lida';
    final semanticPriority = isCritical ? ', crítico' : '';

    return Semantics(
      button: onTap != null,
      label: '$_categoryLabel: $title, $semanticStatus$semanticPriority',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.radius8),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.spacing12),
          decoration: BoxDecoration(
            color: isUnread
                ? Color.alphaBlend(
                    categoryColor.withValues(alpha: 0.08),
                    colors.surface,
                  )
                : colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.radius8),
            border: Border.all(color: colors.outline.withValues(alpha: 0.18)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(_categoryIcon, color: categoryColor),
              const SizedBox(width: AppSpacing.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyLarge.copyWith(
                              color: colors.onSurface,
                              fontWeight: isUnread
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (isUnread) ...<Widget>[
                          const SizedBox(width: AppSpacing.spacing8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.spacing4),
                    Text(
                      body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        color: colors.outline,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.spacing8),
                    if (isCritical) ...<Widget>[
                      const AppStatusBadge(
                        label: 'Crítico',
                        variant: AppStatusBadgeVariant.error,
                        icon: Icons.priority_high,
                      ),
                      const SizedBox(height: AppSpacing.spacing8),
                    ],
                    Text(
                      timestampLabel,
                      style: AppTypography.labelMedium.copyWith(
                        color: colors.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
