import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/approach_suggestion_reference.dart';
import '../cubit/approach_suggestion_cubit.dart';
import '../cubit/approach_suggestion_state.dart';

/// "Sugerir abordagem" sheet (TASK-187, EPIC-28) — opened from the customer
/// 360 (TASK-052) and from the central de oportunidades (TASK-132).
/// Generates a short commercial-approach draft on demand (never
/// automatically) from real customer history (recent orders, CRM
/// activities, active insights) and always shows it in an editable field:
/// `tasks.md`/TASK-187: "sempre editável pelo vendedor antes de qualquer uso
/// em contato real — nunca enviada automaticamente ao cliente". Nothing in
/// this widget ever sends a message or contacts the customer itself —
/// [onUseAsActivity] only hands the (possibly edited) text back to the
/// caller, which decides what to do with it (e.g. pre-fill the existing
/// "Registrar atividade" sheet).
class ApproachSuggestionSheet extends StatelessWidget {
  const ApproachSuggestionSheet({
    super.key,
    required this.organizationId,
    required this.companyId,
    required this.customerId,
    required this.customerName,
    required this.onUseAsActivity,
  });

  final String organizationId;
  final String companyId;
  final String customerId;
  final String customerName;

  /// Called with the seller's final (possibly edited) draft text when they
  /// tap "Usar como atividade" — never called automatically.
  final void Function(String editedText) onUseAsActivity;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ApproachSuggestionCubit, ApproachSuggestionState>(
      builder: (context, state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.auto_awesome, color: context.colors.primary),
                const SizedBox(width: AppSpacing.spacing8),
                Expanded(
                  child: Text(
                    'Sugestão de abordagem — $customerName',
                    style: AppTypography.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.spacing12),
            _ApproachSuggestionBody(
              state: state,
              onGenerate: () =>
                  context.read<ApproachSuggestionCubit>().generate(
                    organizationId: organizationId,
                    companyId: companyId,
                    customerId: customerId,
                  ),
              onUseAsActivity: onUseAsActivity,
            ),
          ],
        );
      },
    );
  }
}

class _ApproachSuggestionBody extends StatelessWidget {
  const _ApproachSuggestionBody({
    required this.state,
    required this.onGenerate,
    required this.onUseAsActivity,
  });

  final ApproachSuggestionState state;
  final VoidCallback onGenerate;
  final void Function(String editedText) onUseAsActivity;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case ApproachSuggestionStatus.idle:
        return _IdlePrompt(onGenerate: onGenerate);
      case ApproachSuggestionStatus.loading:
        return const _LoadingPlaceholder();
      case ApproachSuggestionStatus.error:
        return _ErrorContent(
          message:
              state.failure?.message ??
              'Não foi possível gerar a sugestão de abordagem.',
          onRetry: onGenerate,
        );
      case ApproachSuggestionStatus.ready:
        final suggestion = state.suggestion;
        if (suggestion == null) {
          return _IdlePrompt(onGenerate: onGenerate);
        }
        return _ReadyContent(
          key: ValueKey<DateTime>(suggestion.generatedAt),
          suggestedText: suggestion.suggestedText,
          references: suggestion.references,
          fromCache: suggestion.fromCache,
          onRegenerate: onGenerate,
          onUseAsActivity: onUseAsActivity,
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
          'Gere um roteiro curto de abordagem com base no histórico real deste '
          'cliente (pedidos, atividades de CRM e oportunidades ativas). O '
          'texto é sempre um rascunho — revise e edite antes de usar.',
          style: AppTypography.bodyMedium.copyWith(
            color: context.colors.outline,
          ),
        ),
        const SizedBox(height: AppSpacing.spacing12),
        AppButton(
          label: 'Sugerir abordagem',
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
    super.key,
    required this.suggestedText,
    required this.references,
    required this.fromCache,
    required this.onRegenerate,
    required this.onUseAsActivity,
  });

  final String suggestedText;
  final List<ApproachSuggestionReference> references;
  final bool fromCache;
  final VoidCallback onRegenerate;
  final void Function(String editedText) onUseAsActivity;

  @override
  State<_ReadyContent> createState() => _ReadyContentState();
}

class _ReadyContentState extends State<_ReadyContent> {
  late final TextEditingController _controller;
  bool _referencesExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: _stripReferenceMarkers(widget.suggestedText),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Rascunho gerado por IA — revise e edite antes de usar. Nunca é '
          'enviado automaticamente ao cliente.',
          style: AppTypography.bodySmall.copyWith(
            color: context.colors.outline,
          ),
        ),
        const SizedBox(height: AppSpacing.spacing8),
        AppTextField(
          controller: _controller,
          label: 'Roteiro de abordagem',
          maxLines: 6,
          semanticLabel: 'Texto sugerido de abordagem, editável',
        ),
        if (widget.fromCache) ...<Widget>[
          const SizedBox(height: AppSpacing.spacing4),
          Text(
            'Sugestão reaproveitada de uma geração recente.',
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
        const SizedBox(height: AppSpacing.spacing12),
        Wrap(
          spacing: AppSpacing.spacing8,
          runSpacing: AppSpacing.spacing8,
          children: <Widget>[
            AppButton(
              label: 'Usar como atividade',
              leadingIcon: Icons.add_task_outlined,
              onPressed: () {
                final edited = _controller.text.trim();
                if (edited.isEmpty) return;
                widget.onUseAsActivity(edited);
              },
            ),
            AppButton(
              label: 'Gerar novamente',
              leadingIcon: Icons.refresh,
              variant: AppButtonVariant.text,
              onPressed: widget.onRegenerate,
            ),
          ],
        ),
      ],
    );
  }

  /// The raw generated text carries `[refs: code1, code2]` markers right
  /// after the sentence(s) they support (the server's own validation
  /// contract, `functions/src/approach_suggestion/approach-suggestion-shared.ts`)
  /// — those are what the "ver fontes" expansion above already surfaces in a
  /// readable form, so the editable field starts from prose without the raw
  /// bracket syntax (same as `WalletSummaryCard`, TASK-186).
  String _stripReferenceMarkers(String text) {
    return text.replaceAll(
      RegExp(r'\s*\[refs:[^\]]*\]', caseSensitive: false),
      '',
    );
  }
}
