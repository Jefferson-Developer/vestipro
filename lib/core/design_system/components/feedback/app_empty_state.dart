import 'package:flutter/material.dart';

import '../../foundations/foundations.dart';
import '../../theme/theme.dart';
import '../buttons/app_button.dart';

/// The generic "nothing to show" state, reused by every list/search result
/// across the app (clients, products, orders, follow-ups, dashboards, ...).
///
/// Deliberately generic: no feature is allowed to build a bespoke empty
/// state widget — configure this one via [icon]/[title]/[description]/
/// [actionLabel] instead.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    this.description,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? description;
  final IconData icon;

  /// If both [actionLabel] and [onAction] are set, a primary button is
  /// rendered below the description.
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: AppIconSizes.xxl, color: colors.outline),
            const SizedBox(height: AppSpacing.spacing16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                color: colors.onSurface,
              ),
            ),
            if (description != null) ...<Widget>[
              const SizedBox(height: AppSpacing.spacing8),
              Text(
                description!,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(color: colors.outline),
              ),
            ],
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: AppSpacing.spacing24),
              AppButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}
