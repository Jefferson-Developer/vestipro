import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/wallet_summary_reference.dart';
import '../cubit/wallet_summary_cubit.dart';
import '../cubit/wallet_summary_state.dart';

/// "Resumo da carteira" card (TASK-186, EPIC-28) — shown on the
/// representative dashboard home. Generates a natural-language summary of
/// the seller's carteira on demand (never automatically, to keep the LLM
/// call under the caller's explicit control) and renders every reference the
/// generated text cited as an expandable citation, so nothing here is ever
/// shown as fact without a traceable source.
class WalletSummaryCard extends StatelessWidget {
  const WalletSummaryCard({
    super.key,
    required this.organizationId,
    required this.companyId,
    required this.requesterUserId,
    required this.sellerId,
  });

  final String organizationId;
  final String companyId;
  final String requesterUserId;
  final String sellerId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletSummaryCubit, WalletSummaryState>(
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
                        'Resumo da carteira',
                        style: AppTypography.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.spacing12),
                _WalletSummaryBody(
                  state: state,
                  onGenerate: () => context.read<WalletSummaryCubit>().generate(
                    organizationId: organizationId,
                    companyId: companyId,
                    requesterUserId: requesterUserId,
                    sellerId: sellerId,
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

class _WalletSummaryBody extends StatelessWidget {
  const _WalletSummaryBody({required this.state, required this.onGenerate});

  final WalletSummaryState state;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case WalletSummaryStatus.idle:
        return _IdlePrompt(onGenerate: onGenerate);
      case WalletSummaryStatus.loading:
        return const _LoadingPlaceholder();
      case WalletSummaryStatus.error:
        return _ErrorContent(
          message:
              state.failure?.message ??
              'Não foi possível gerar o resumo da carteira.',
          onRetry: onGenerate,
        );
      case WalletSummaryStatus.ready:
        final summary = state.summary;
        if (summary == null) {
          return _IdlePrompt(onGenerate: onGenerate);
        }
        return _ReadyContent(
          summaryText: summary.summaryText,
          references: summary.references,
          generatedAt: summary.generatedAt,
          fromCache: summary.fromCache,
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
          'Gere um resumo em linguagem natural com destaques, riscos e '
          'oportunidades da sua carteira, com base nos dados já calculados '
          'pelo sistema.',
          style: AppTypography.bodyMedium.copyWith(
            color: context.colors.outline,
          ),
        ),
        const SizedBox(height: AppSpacing.spacing12),
        AppButton(
          label: 'Gerar resumo',
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
    required this.summaryText,
    required this.references,
    required this.generatedAt,
    required this.fromCache,
    required this.onRegenerate,
  });

  final String summaryText;
  final List<WalletSummaryReference> references;
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
          _stripReferenceMarkers(widget.summaryText),
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.spacing8),
        Text(
          '${widget.fromCache ? 'Resumo em cache. ' : ''}Gerado em '
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
  /// contract, `functions/src/wallet_summary/wallet-summary-shared.ts`) —
  /// those are what the "ver fontes" expansion above already surfaces in a
  /// readable form, so the running prose itself is shown without the raw
  /// bracket syntax.
  String _stripReferenceMarkers(String text) {
    return text.replaceAll(
      RegExp(r'\s*\[refs:[^\]]*\]', caseSensitive: false),
      '',
    );
  }
}
