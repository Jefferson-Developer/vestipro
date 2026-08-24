import 'package:flutter/material.dart';

import '../../foundations/foundations.dart';
import '../../theme/theme.dart';

class AppTimelineEntry {
  const AppTimelineEntry({
    required this.title,
    required this.icon,
    required this.timestampLabel,
    required this.description,
    this.subtitle,
    this.badges = const <Widget>[],
    this.isHighlighted = false,
    this.semanticLabel,
  });

  final String title;
  final IconData icon;
  final String timestampLabel;
  final String description;
  final String? subtitle;
  final List<Widget> badges;
  final bool isHighlighted;
  final String? semanticLabel;
}

class AppTimeline extends StatelessWidget {
  const AppTimeline({required this.entries, super.key});

  final List<AppTimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (var index = 0; index < entries.length; index++)
          _AppTimelineTile(
            entry: entries[index],
            isLast: index == entries.length - 1,
          ),
      ],
    );
  }
}

class _AppTimelineTile extends StatelessWidget {
  const _AppTimelineTile({required this.entry, required this.isLast});

  final AppTimelineEntry entry;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = entry.isHighlighted ? colors.warning : colors.primary;
    return Semantics(
      label: entry.semanticLabel,
      container: true,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              width: AppSpacing.spacing40,
              child: Column(
                children: <Widget>[
                  Container(
                    width: AppSpacing.spacing32,
                    height: AppSpacing.spacing32,
                    decoration: BoxDecoration(
                      color: Color.alphaBlend(
                        accent.withValues(alpha: 0.16),
                        colors.surface,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: accent),
                    ),
                    child: Icon(
                      entry.icon,
                      size: AppIconSizes.md,
                      color: accent,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 1,
                        margin: const EdgeInsets.symmetric(
                          vertical: AppSpacing.spacing4,
                        ),
                        color: colors.outline.withValues(alpha: 0.24),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.spacing12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: isLast ? 0 : AppSpacing.spacing12,
                ),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.spacing12),
                  decoration: BoxDecoration(
                    color: entry.isHighlighted
                        ? Color.alphaBlend(
                            colors.warning.withValues(alpha: 0.10),
                            colors.surface,
                          )
                        : colors.background,
                    borderRadius: BorderRadius.circular(AppRadius.radius8),
                    border: Border.all(
                      color: entry.isHighlighted
                          ? colors.warning.withValues(alpha: 0.54)
                          : colors.outline.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              entry.title,
                              style: AppTypography.labelLarge.copyWith(
                                color: colors.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.spacing8),
                          Text(
                            entry.timestampLabel,
                            style: AppTypography.labelMedium.copyWith(
                              color: colors.outline,
                            ),
                          ),
                        ],
                      ),
                      if (entry.subtitle?.trim().isNotEmpty ?? false) ...[
                        const SizedBox(height: AppSpacing.spacing4),
                        Text(
                          entry.subtitle!,
                          style: AppTypography.bodySmall.copyWith(
                            color: colors.outline,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.spacing8),
                      Text(
                        entry.description,
                        style: AppTypography.bodyMedium.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                      if (entry.badges.isNotEmpty) ...<Widget>[
                        const SizedBox(height: AppSpacing.spacing8),
                        Wrap(
                          spacing: AppSpacing.spacing8,
                          runSpacing: AppSpacing.spacing8,
                          children: entry.badges,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
