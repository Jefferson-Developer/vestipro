import 'package:flutter/material.dart';

import '../../foundations/foundations.dart';
import '../../theme/theme.dart';

/// The direction a metric moved compared to its reference period.
///
/// Rendered with a dedicated icon (never color alone) so tendency is legible
/// for color-blind users and in grayscale printouts/screenshots — the same
/// guarantee [AppStatusBadge] already gives status pills.
enum AppKpiTrend {
  /// The metric improved vs. the reference period.
  up,

  /// The metric worsened vs. the reference period.
  down,

  /// No meaningful change, or no reference period to compare against.
  neutral,
}

/// The metric/KPI card every dashboard (executivo, vendas, clientes,
/// produtos, metas, ...) reuses to headline a single number.
///
/// [AppKpiCard] never computes [value]/[trendPercentage] itself — both are
/// already-formatted strings/numbers decided by the domain/BLoC layer. This
/// widget only lays them out consistently and renders the trend indicator.
///
/// ```dart
/// AppKpiCard(
///   label: 'Faturamento (mês)',
///   value: 'R\$ 128.400',
///   trend: AppKpiTrend.up,
///   trendPercentage: 12.5,
///   trendLabel: 'vs. mês anterior',
/// )
/// ```
class AppKpiCard extends StatelessWidget {
  const AppKpiCard({
    super.key,
    required this.label,
    required this.value,
    this.trend = AppKpiTrend.neutral,
    this.trendPercentage,
    this.trendLabel,
    this.icon,
    this.semanticLabel,
  });

  /// The metric's name (e.g. "Faturamento (mês)"). Always caller-provided
  /// (i18n-ready).
  final String label;

  /// The already-formatted headline value (e.g. "R\$ 128.400", "342
  /// pedidos"). [AppKpiCard] never formats currency/number values itself —
  /// that is a domain/localization concern, not a Design System one.
  final String value;

  final AppKpiTrend trend;

  /// The already-computed variation vs. the reference period (e.g. `12.5`
  /// for "+12,5%"). When `null`, no trend row is rendered at all.
  final double? trendPercentage;

  /// Describes the reference period (e.g. "vs. mês anterior"). Shown next
  /// to [trendPercentage] when both are provided.
  final String? trendLabel;

  final IconData? icon;
  final String? semanticLabel;

  IconData get _trendIcon => switch (trend) {
    AppKpiTrend.up => Icons.trending_up,
    AppKpiTrend.down => Icons.trending_down,
    AppKpiTrend.neutral => Icons.trending_flat,
  };

  Color _trendColor(AppColors colors) => switch (trend) {
    AppKpiTrend.up => colors.success,
    AppKpiTrend.down => colors.error,
    AppKpiTrend.neutral => colors.outline,
  };

  String _formattedPercentage(double percentage) {
    final sign = percentage > 0 ? '+' : '';
    return '$sign${percentage.toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final trendColor = _trendColor(colors);

    return Semantics(
      label:
          semanticLabel ??
          '$label: $value'
              '${trendPercentage != null ? ', variação ${_formattedPercentage(trendPercentage!)}${trendLabel != null ? ' $trendLabel' : ''}' : ''}',
      container: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.spacing16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.radius16),
          border: Border.all(color: colors.outline.withValues(alpha: 0.16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.bodyMedium.copyWith(
                      color: colors.outline,
                    ),
                  ),
                ),
                if (icon != null)
                  Icon(icon, size: AppIconSizes.lg, color: colors.outline),
              ],
            ),
            const SizedBox(height: AppSpacing.spacing8),
            Text(
              value,
              style: AppTypography.headlineMedium.copyWith(
                color: colors.onSurface,
              ),
            ),
            if (trendPercentage != null) ...<Widget>[
              const SizedBox(height: AppSpacing.spacing8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(_trendIcon, size: AppIconSizes.sm, color: trendColor),
                  const SizedBox(width: AppSpacing.spacing4),
                  Text(
                    _formattedPercentage(trendPercentage!),
                    style: AppTypography.labelMedium.copyWith(
                      color: trendColor,
                    ),
                  ),
                  if (trendLabel != null) ...<Widget>[
                    const SizedBox(width: AppSpacing.spacing4),
                    Expanded(
                      child: Text(
                        trendLabel!,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: colors.outline,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
