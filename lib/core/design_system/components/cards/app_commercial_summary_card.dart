import 'package:flutter/material.dart';

import '../../foundations/foundations.dart';
import '../../theme/theme.dart';

/// How one [AppCommercialSummaryLine]'s value should read visually — a
/// discount reads as [positive] (it lowers what the customer pays), an
/// acréscimo/surcharge as [negative]; a plain subtotal/frete/total stays
/// [neutral]. Never color-only: [AppCommercialSummaryLine.label] itself
/// already says what the row is, same rule [AppStatusBadge] follows.
enum AppCommercialSummaryLineTone { neutral, positive, negative }

/// One labeled money row inside [AppCommercialSummaryCard] (e.g. "Subtotal",
/// "Desconto", "Acréscimo", "Frete", "Total"). [value] is always an
/// already-formatted string — this component never formats currency itself,
/// same precedent [AppKpiCard.value] already sets, and never computes what
/// the row shows either: that is always a domain/pricing-engine concern
/// (TASK-099's "nunca um cálculo divergente feito apenas na interface"
/// rule).
class AppCommercialSummaryLine {
  const AppCommercialSummaryLine({
    required this.label,
    required this.value,
    this.tone = AppCommercialSummaryLineTone.neutral,
    this.emphasis = false,
  });

  final String label;
  final String value;
  final AppCommercialSummaryLineTone tone;

  /// `true` for the row that should stand out (typically "Total").
  final bool emphasis;
}

/// The commercial summary card every "resumo do pedido"/checkout-like screen
/// reuses to show subtotal/desconto/acréscimo/frete/total (TASK-099,
/// EPIC-13). Purely a layout component: [lines] already carry every
/// formatted value, [statusBadge] already carries whatever "recalculando"/
/// "estimativa não confirmada"/error state the caller resolved, and
/// [footnote] is already the exact message to show below the totals — this
/// widget never derives any of them.
class AppCommercialSummaryCard extends StatelessWidget {
  const AppCommercialSummaryCard({
    required this.lines,
    this.title,
    this.statusBadge,
    this.footnote,
    super.key,
  });

  final List<AppCommercialSummaryLine> lines;
  final String? title;

  /// Typically an [AppStatusBadge] (e.g. "Recalculando...", "Estimativa não
  /// confirmada") — its own `Semantics` already announces the status text,
  /// so nothing extra is added here.
  final Widget? statusBadge;

  /// A short explanatory note shown below every line (e.g. "Total oficial:
  /// aguardando confirmação do motor de precificação.").
  final String? footnote;

  Color _toneColor(AppColors colors, AppCommercialSummaryLineTone tone) {
    return switch (tone) {
      AppCommercialSummaryLineTone.positive => colors.success,
      AppCommercialSummaryLineTone.negative => colors.error,
      AppCommercialSummaryLineTone.neutral => colors.onSurface,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasHeader = title != null || statusBadge != null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.radius8),
        border: Border.all(color: colors.outline.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (hasHeader) ...<Widget>[
            Row(
              children: <Widget>[
                if (title != null)
                  Expanded(
                    child: Text(
                      title!,
                      style: AppTypography.titleMedium.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ?statusBadge,
              ],
            ),
            const SizedBox(height: AppSpacing.spacing12),
          ],
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.spacing8),
              child: Semantics(
                label: '${line.label}: ${line.value}',
                container: true,
                // Merges the row into a single announcement (e.g. "Subtotal:
                // R$ 100,00") instead of the label and value being read as
                // two separate, redundant nodes on top of this one.
                excludeSemantics: true,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        line.label,
                        style:
                            (line.emphasis
                                    ? AppTypography.titleMedium
                                    : AppTypography.bodyMedium)
                                .copyWith(
                                  color: line.emphasis
                                      ? colors.onSurface
                                      : colors.outline,
                                ),
                      ),
                    ),
                    Text(
                      line.value,
                      style:
                          (line.emphasis
                                  ? AppTypography.titleMedium
                                  : AppTypography.bodyMedium)
                              .copyWith(color: _toneColor(colors, line.tone)),
                    ),
                  ],
                ),
              ),
            ),
          if (footnote != null) ...<Widget>[
            const SizedBox(height: AppSpacing.spacing4),
            Text(
              footnote!,
              style: AppTypography.bodySmall.copyWith(color: colors.outline),
            ),
          ],
        ],
      ),
    );
  }
}
