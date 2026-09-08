import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/daily_rep_summary.dart';
import '../../domain/entities/daily_rep_summary_reference.dart';
import '../cubit/daily_rep_summary_cubit.dart';
import '../cubit/daily_rep_summary_state.dart';

/// "Resumo do dia" card (TASK-188, EPIC-28) — fixed at the top of the
/// representative dashboard home. Loads automatically (the summary was
/// already produced by the `generateDailyRepSummary` schedule earlier that
/// morning — this card never triggers an LLM call itself) and renders every
/// reference the generated text cited as an expandable citation, so nothing
/// here is ever shown as fact without a traceable source. A failure here
/// (provider unavailable, not generated yet) never blocks the rest of the
/// home — it is rendered as its own contained, friendly state.
class DailyRepSummaryCard extends StatelessWidget {
  const DailyRepSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DailyRepSummaryCubit, DailyRepSummaryState>(
      builder: (context, state) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.wb_sunny_outlined,
                      color: context.colors.primary,
                    ),
                    const SizedBox(width: AppSpacing.spacing8),
                    Expanded(
                      child: Text(
                        'Resumo do dia',
                        style: AppTypography.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.spacing12),
                _DailyRepSummaryBody(state: state),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DailyRepSummaryBody extends StatelessWidget {
  const _DailyRepSummaryBody({required this.state});

  final DailyRepSummaryState state;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case DailyRepSummaryCardStatus.loading:
        return const _LoadingPlaceholder();
      case DailyRepSummaryCardStatus.error:
        return _MessageContent(
          icon: Icons.error_outline,
          message:
              state.failure?.message ??
              'Não foi possível carregar o resumo do dia.',
        );
      case DailyRepSummaryCardStatus.loaded:
        final summary = state.summary;
        if (summary == null) {
          return const _MessageContent(
            icon: Icons.hourglass_empty,
            message: 'Seu resumo de hoje ainda está sendo preparado.',
          );
        }
        return switch (summary.status) {
          DailyRepSummaryResultStatus.ready => _ReadyContent(
            summaryText: summary.summaryText!,
            references: summary.references,
            generatedAt: summary.generatedAt,
          ),
          DailyRepSummaryResultStatus.empty => const _MessageContent(
            icon: Icons.check_circle_outline,
            message:
                'Nada urgente para hoje. Bom momento para prospecção e '
                'follow-ups em dia.',
          ),
          DailyRepSummaryResultStatus.error => const _MessageContent(
            icon: Icons.error_outline,
            message:
                'Não foi possível gerar seu resumo hoje. Um novo resumo é '
                'gerado automaticamente amanhã.',
          ),
          DailyRepSummaryResultStatus.notGeneratedYet => const _MessageContent(
            icon: Icons.hourglass_empty,
            message: 'Seu resumo de hoje ainda está sendo preparado.',
          ),
        };
    }
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AppSkeleton.line(),
        SizedBox(height: AppSpacing.spacing8),
        AppSkeleton.line(),
        SizedBox(height: AppSpacing.spacing8),
        AppSkeleton.line(width: 180),
      ],
    );
  }
}

class _MessageContent extends StatelessWidget {
  const _MessageContent({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, color: context.colors.outline),
        const SizedBox(width: AppSpacing.spacing8),
        Expanded(
          child: Text(
            message,
            style: AppTypography.bodyMedium.copyWith(
              color: context.colors.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadyContent extends StatefulWidget {
  const _ReadyContent({
    required this.summaryText,
    required this.references,
    required this.generatedAt,
  });

  final String summaryText;
  final List<DailyRepSummaryReference> references;
  final DateTime? generatedAt;

  @override
  State<_ReadyContent> createState() => _ReadyContentState();
}

class _ReadyContentState extends State<_ReadyContent> {
  bool _referencesExpanded = false;

  @override
  Widget build(BuildContext context) {
    final generatedAt = widget.generatedAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          _stripReferenceMarkers(widget.summaryText),
          style: AppTypography.bodyMedium,
        ),
        if (generatedAt != null) ...<Widget>[
          const SizedBox(height: AppSpacing.spacing8),
          Text(
            'Gerado às ${DateFormat('HH:mm', 'pt_BR').format(generatedAt.toLocal())}',
            style: AppTypography.bodySmall.copyWith(
              color: context.colors.outline,
            ),
          ),
        ],
        if (widget.references.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.spacing8),
          TextButton.icon(
            onPressed: () =>
                setState(() => _referencesExpanded = !_referencesExpanded),
            icon: Icon(
              _referencesExpanded ? Icons.expand_less : Icons.expand_more,
            ),
            label: Text(
              _referencesExpanded
                  ? 'Ocultar fontes dos dados'
                  : 'Ver fontes dos dados (${widget.references.length})',
            ),
          ),
          if (_referencesExpanded)
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.spacing8,
                bottom: AppSpacing.spacing8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.references
                    .map(
                      (reference) => Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.spacing4,
                        ),
                        child: Text(
                          '• ${reference.label}: ${reference.value}'
                          '${reference.unit != null ? ' ${reference.unit}' : ''}',
                          style: AppTypography.bodySmall,
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
        ],
      ],
    );
  }

  /// The raw generated text carries `[refs: code1, code2]` markers right
  /// after the sentence(s) they support (the server's own validation
  /// contract, `functions/src/daily_rep_summary/daily-rep-summary-shared.ts`)
  /// — those are what the "ver fontes" expansion above already surfaces in a
  /// readable form, so the running prose itself is shown without the raw
  /// bracket syntax (mirrors `WalletSummaryCard`'s own
  /// `_stripReferenceMarkers`).
  String _stripReferenceMarkers(String text) {
    return text.replaceAll(
      RegExp(r'\s*\[refs:[^\]]*\]', caseSensitive: false),
      '',
    );
  }
}
