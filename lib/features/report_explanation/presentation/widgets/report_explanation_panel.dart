import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../reports/domain/entities/report_definition.dart';
import '../../domain/entities/report_explanation_reference.dart';
import '../cubit/report_explanation_cubit.dart';
import '../cubit/report_explanation_state.dart';

/// "Explicar este relatório" panel (TASK-189, EPIC-28) — shown alongside a
/// report's chart/table, both in the construtor de relatórios (TASK-144) and
/// in existing dashboards. Generates a natural-language explanation of the
/// already-executed report on demand (never automatically) and renders
/// every reference the generated text cited as an expandable citation, so
/// nothing here is ever shown as fact without a traceable source back to
/// the report's own already-validated numbers.
class ReportExplanationPanel extends StatelessWidget {
  const ReportExplanationPanel({
    super.key,
    required this.definition,
    this.savedReportId,
  });

  final ReportDefinition definition;
  final String? savedReportId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportExplanationCubit, ReportExplanationState>(
      builder: (context, state) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.auto_awesome, color: context.colors.primary),
                    const SizedBox(width: AppSpacing.spacing8),
                    Expanded(
                      child: Text(
                        'Explicação do relatório',
                        style: AppTypography.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.spacing12),
                _ReportExplanationBody(
                  state: state,
                  onGenerate: () =>
                      context.read<ReportExplanationCubit>().explain(
                        definition: definition,
                        savedReportId: savedReportId,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReportExplanationBody extends StatelessWidget {
  const _ReportExplanationBody({required this.state, required this.onGenerate});

  final ReportExplanationState state;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case ReportExplanationStatus.idle:
        return _IdlePrompt(onGenerate: onGenerate);
      case ReportExplanationStatus.loading:
        return const _LoadingPlaceholder();
      case ReportExplanationStatus.error:
        return _ErrorContent(
          message:
              state.failure?.message ??
              'Não foi possível gerar a explicação deste relatório.',
          onRetry: onGenerate,
        );
      case ReportExplanationStatus.ready:
        final explanation = state.explanation;
        if (explanation == null) {
          return _IdlePrompt(onGenerate: onGenerate);
        }
        return _ReadyContent(
          explanationText: explanation.explanationText,
          references: explanation.references,
          generatedAt: explanation.generatedAt,
          fromCache: explanation.fromCache,
          onRegenerate: onGenerate,
        );
    }
  }
}

class _IdlePrompt extends StatelessWidget {
  const _IdlePrompt({required this.onGenerate});
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Gere uma explicação em linguagem natural com as tendências e '
          'destaques deste relatório, com base nos dados já calculados '
          'pelo sistema.',
          style: AppTypography.bodyMedium.copyWith(
            color: context.colors.outline,
          ),
        ),
        const SizedBox(height: AppSpacing.spacing12),
        AppButton(
          label: 'Explicar este relatório',
          leadingIcon: Icons.auto_awesome,
          onPressed: onGenerate,
        ),
      ],
    );
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

class _ErrorContent extends StatelessWidget {
  const _ErrorContent({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.error_outline, color: context.colors.error),
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
        ),
        const SizedBox(height: AppSpacing.spacing12),
        AppButton(
          label: 'Tentar novamente',
          leadingIcon: Icons.refresh,
          variant: AppButtonVariant.secondary,
          onPressed: onRetry,
        ),
      ],
    );
  }
}

class _ReadyContent extends StatefulWidget {
  const _ReadyContent({
    required this.explanationText,
    required this.references,
    required this.generatedAt,
    required this.fromCache,
    required this.onRegenerate,
  });

  final String explanationText;
  final List<ReportExplanationReference> references;
  final DateTime generatedAt;
  final bool fromCache;
  final VoidCallback onRegenerate;

  @override
  State<_ReadyContent> createState() => _ReadyContentState();
}

class _ReadyContentState extends State<_ReadyContent> {
  bool _referencesExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          _stripReferenceMarkers(widget.explanationText),
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.spacing8),
        Text(
          '${widget.fromCache ? 'Explicação em cache. ' : ''}Gerado em '
          '${DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(widget.generatedAt.toLocal())}',
          style: AppTypography.bodySmall.copyWith(
            color: context.colors.outline,
          ),
        ),
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
        const SizedBox(height: AppSpacing.spacing8),
        AppButton(
          label: 'Gerar novamente',
          leadingIcon: Icons.refresh,
          variant: AppButtonVariant.text,
          onPressed: widget.onRegenerate,
        ),
      ],
    );
  }

  /// The raw generated text carries `[refs: code1, code2]` markers right
  /// after the sentence(s) they support (the server's own validation
  /// contract, `functions/src/report_explanation/report-explanation-shared.ts`)
  /// — those are what the "ver fontes" expansion above already surfaces in a
  /// readable form, so the running prose itself is shown without the raw
  /// bracket syntax.
  String _stripReferenceMarkers(String text) {
    return text.replaceAll(
      RegExp(r'\s*\[refs:[^\]]*\]', caseSensitive: false),
      '',
    );
  }
}
