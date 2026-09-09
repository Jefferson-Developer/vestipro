import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../cubit/campaign_assist_cubit.dart';
import '../cubit/campaign_assist_state.dart';

/// "Gerar sugestão com IA" sheet, opened from `CampaignFormPage` (TASK-080)
/// — TASK-192, EPIC-28. Generates an editable draft (title/subtitle/
/// description) for the campaign being created from parameters the admin
/// supplies here (público-alvo, tom de comunicação) plus what is already
/// selected in the form itself (produtos relacionados, período) — never
/// re-asks for those, avoiding a duplicate picker.
///
/// Nothing in this widget ever saves/publishes a `CatalogCampaign` itself —
/// [onUseSuggestion] only hands the (possibly edited) title/subtitle/
/// description back to `CampaignFormPage`, which pre-fills its own already-
/// existing editable fields; the admin still explicitly taps "Criar
/// campanha"/"Salvar alterações" to publish (`tasks.md`/TASK-192: "sempre
/// como rascunho revisável antes de publicar — nunca publicando
/// automaticamente").
class CampaignAssistSheet extends StatefulWidget {
  const CampaignAssistSheet({
    super.key,
    required this.organizationId,
    required this.productIds,
    required this.productCount,
    this.startAt,
    this.endAt,
    required this.onUseSuggestion,
  });

  final String organizationId;

  /// The campaign form's currently-selected related-product ids — passed
  /// through as-is; the server independently re-resolves each one against
  /// this organization's own products (never trusted as a name/category
  /// string).
  final List<String> productIds;

  /// Same length as [productIds] — kept as a separate, explicit parameter so
  /// the sheet never needs the full `Product` list just to display a count.
  final int productCount;
  final DateTime? startAt;
  final DateTime? endAt;

  /// Called with the (possibly edited) draft text when the admin taps "Usar
  /// sugestão" — never called automatically.
  final void Function({
    required String title,
    required String subtitle,
    required String description,
  })
  onUseSuggestion;

  @override
  State<CampaignAssistSheet> createState() => _CampaignAssistSheetState();
}

class _CampaignAssistSheetState extends State<CampaignAssistSheet> {
  final TextEditingController _audienceController = TextEditingController();
  final TextEditingController _toneController = TextEditingController();

  @override
  void dispose() {
    _audienceController.dispose();
    _toneController.dispose();
    super.dispose();
  }

  void _generate(BuildContext context) {
    unawaited(
      context.read<CampaignAssistCubit>().generate(
        organizationId: widget.organizationId,
        productIds: widget.productIds,
        audienceDescription: _audienceController.text,
        tone: _toneController.text,
        startAt: widget.startAt,
        endAt: widget.endAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CampaignAssistCubit, CampaignAssistState>(
      builder: (context, state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.auto_awesome, color: context.colors.primary),
                const SizedBox(width: AppSpacing.spacing8),
                const Expanded(
                  child: Text(
                    'Gerar sugestão com IA',
                    style: AppTypography.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.spacing8),
            Text(
              widget.productCount > 0
                  ? '${widget.productCount} produto(s) selecionado(s) nesta campanha serão usados como base.'
                  : 'Nenhum produto selecionado ainda — a sugestão será mais genérica.',
              style: AppTypography.bodySmall.copyWith(
                color: context.colors.outline,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing12),
            _CampaignAssistBody(
              state: state,
              audienceController: _audienceController,
              toneController: _toneController,
              onGenerate: () => _generate(context),
              onUseSuggestion: widget.onUseSuggestion,
            ),
          ],
        );
      },
    );
  }
}

class _CampaignAssistBody extends StatelessWidget {
  const _CampaignAssistBody({
    required this.state,
    required this.audienceController,
    required this.toneController,
    required this.onGenerate,
    required this.onUseSuggestion,
  });

  final CampaignAssistState state;
  final TextEditingController audienceController;
  final TextEditingController toneController;
  final VoidCallback onGenerate;
  final void Function({
    required String title,
    required String subtitle,
    required String description,
  })
  onUseSuggestion;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case CampaignAssistStatus.idle:
        return _InputForm(
          audienceController: audienceController,
          toneController: toneController,
          onGenerate: onGenerate,
        );
      case CampaignAssistStatus.loading:
        return const _LoadingPlaceholder();
      case CampaignAssistStatus.error:
        return _ErrorContent(
          message:
              state.failure?.message ??
              'Não foi possível gerar a sugestão de campanha.',
          onRetry: onGenerate,
        );
      case CampaignAssistStatus.ready:
        final draft = state.draft;
        if (draft == null) {
          return _InputForm(
            audienceController: audienceController,
            toneController: toneController,
            onGenerate: onGenerate,
          );
        }
        return _ReadyContent(
          key: ValueKey<DateTime>(draft.generatedAt),
          initialTitle: draft.title,
          initialSubtitle: draft.subtitle,
          initialDescription: draft.description,
          fromCache: draft.fromCache,
          onRegenerate: onGenerate,
          onUseSuggestion: onUseSuggestion,
        );
    }
  }
}

class _InputForm extends StatelessWidget {
  const _InputForm({
    required this.audienceController,
    required this.toneController,
    required this.onGenerate,
  });

  final TextEditingController audienceController;
  final TextEditingController toneController;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: audienceController,
      builder: (context, audienceValue, _) {
        return ValueListenableBuilder<TextEditingValue>(
          valueListenable: toneController,
          builder: (context, toneValue, _) {
            final canGenerate =
                audienceValue.text.trim().isNotEmpty &&
                toneValue.text.trim().isNotEmpty;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AppTextField(
                  controller: audienceController,
                  label: 'Público-alvo',
                  hintText:
                      'Ex.: clientes urbanos que buscam moda casual premium',
                  maxLines: 2,
                  isRequired: true,
                ),
                const SizedBox(height: AppSpacing.spacing12),
                AppTextField(
                  controller: toneController,
                  label: 'Tom de comunicação',
                  hintText: 'Ex.: sofisticado e aspiracional',
                  isRequired: true,
                ),
                const SizedBox(height: AppSpacing.spacing16),
                Text(
                  'A sugestão é sempre um rascunho — revise e edite antes de '
                  'usar. Nunca é publicada automaticamente.',
                  style: AppTypography.bodySmall.copyWith(
                    color: context.colors.outline,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing12),
                AppButton(
                  label: 'Gerar sugestão',
                  leadingIcon: Icons.auto_awesome,
                  isDisabled: !canGenerate,
                  onPressed: canGenerate ? onGenerate : null,
                ),
              ],
            );
          },
        );
      },
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
    required this.initialTitle,
    required this.initialSubtitle,
    required this.initialDescription,
    required this.fromCache,
    required this.onRegenerate,
    required this.onUseSuggestion,
  });

  final String initialTitle;
  final String initialSubtitle;
  final String initialDescription;
  final bool fromCache;
  final VoidCallback onRegenerate;
  final void Function({
    required String title,
    required String subtitle,
    required String description,
  })
  onUseSuggestion;

  @override
  State<_ReadyContent> createState() => _ReadyContentState();
}

class _ReadyContentState extends State<_ReadyContent> {
  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _subtitleController = TextEditingController(text: widget.initialSubtitle);
    _descriptionController = TextEditingController(
      text: widget.initialDescription,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Rascunho gerado por IA — revise e edite antes de usar. Nunca é '
          'publicado automaticamente.',
          style: AppTypography.bodySmall.copyWith(
            color: context.colors.outline,
          ),
        ),
        const SizedBox(height: AppSpacing.spacing8),
        AppTextField(
          controller: _titleController,
          label: 'Título da campanha',
          semanticLabel: 'Título sugerido, editável',
        ),
        const SizedBox(height: AppSpacing.spacing12),
        AppTextField(
          controller: _subtitleController,
          label: 'Subtítulo',
          semanticLabel: 'Subtítulo sugerido, editável',
        ),
        const SizedBox(height: AppSpacing.spacing12),
        AppTextField(
          controller: _descriptionController,
          label: 'Texto editorial',
          maxLines: 5,
          semanticLabel: 'Texto editorial sugerido, editável',
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
        const SizedBox(height: AppSpacing.spacing12),
        Wrap(
          spacing: AppSpacing.spacing8,
          runSpacing: AppSpacing.spacing8,
          children: <Widget>[
            AppButton(
              label: 'Usar sugestão',
              leadingIcon: Icons.check,
              onPressed: () {
                final title = _titleController.text.trim();
                final subtitle = _subtitleController.text.trim();
                final description = _descriptionController.text.trim();
                if (title.isEmpty) return;
                widget.onUseSuggestion(
                  title: title,
                  subtitle: subtitle,
                  description: description,
                );
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
}
