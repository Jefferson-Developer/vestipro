import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/product_recognition_candidate.dart';
import '../../domain/entities/product_recognition_result.dart';
import '../../domain/value_objects/product_recognition_feedback_outcome.dart';
import '../cubit/product_recognition_cubit.dart';
import '../cubit/product_recognition_state.dart';

/// "Identificar produto por foto" screen (TASK-191, EPIC-28): captures a
/// photo (camera or gallery) and shows a ranked list of catalog candidates —
/// never a single forced answer, and never an automatic navigation to a
/// product. The seller always confirms one candidate ("abrir produto") or
/// explicitly says none matched ("nenhum destes") before anything happens.
class ProductRecognitionPage extends StatelessWidget {
  const ProductRecognitionPage({
    required this.organizationId,
    required this.companyId,
    required this.createCubit,
    required this.onProductSelected,
    super.key,
  });

  final String organizationId;
  final String companyId;
  final ProductRecognitionCubit Function() createCubit;

  /// Called after the seller confirms a candidate really is the product
  /// (feedback already recorded) — the caller decides where "abrir produto"
  /// navigates to (e.g. `ProductDetailRoute`).
  final void Function(String productId) onProductSelected;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProductRecognitionCubit>(
      create: (_) => createCubit(),
      child: _ProductRecognitionView(
        organizationId: organizationId,
        companyId: companyId,
        onProductSelected: onProductSelected,
      ),
    );
  }
}

class _ProductRecognitionView extends StatelessWidget {
  const _ProductRecognitionView({
    required this.organizationId,
    required this.companyId,
    required this.onProductSelected,
  });

  final String organizationId;
  final String companyId;
  final void Function(String productId) onProductSelected;

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final cubit = context.read<ProductRecognitionCubit>();
    final file = await ImagePicker().pickImage(source: source);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!context.mounted) return;
    unawaited(
      cubit.recognize(
        organizationId: organizationId,
        companyId: companyId,
        imageBytes: bytes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductRecognitionCubit, ProductRecognitionState>(
      listenWhen: (previous, current) =>
          previous.status != ProductRecognitionStatus.error &&
          current.status == ProductRecognitionStatus.error,
      listener: (context, state) {
        AppSnackbar.show(
          context,
          message:
              state.failure?.message ??
              'Não foi possível identificar o produto por foto.',
          variant: AppSnackbarVariant.error,
        );
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Identificar produto por foto')),
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.spacing16),
            child: _Body(
              state: state,
              organizationId: organizationId,
              onPickCamera: () => _pick(context, ImageSource.camera),
              onPickGallery: () => _pick(context, ImageSource.gallery),
              onRetry: () => context.read<ProductRecognitionCubit>().reset(),
              onCandidateSelected: (candidate) async {
                await context.read<ProductRecognitionCubit>().submitFeedback(
                  organizationId: organizationId,
                  outcome: ProductRecognitionFeedbackOutcome.matched,
                  matchedProductId: candidate.productId,
                );
                onProductSelected(candidate.productId);
              },
              onNoneMatch: () async {
                await context.read<ProductRecognitionCubit>().submitFeedback(
                  organizationId: organizationId,
                  outcome: ProductRecognitionFeedbackOutcome.noneMatched,
                );
                if (context.mounted) {
                  context.read<ProductRecognitionCubit>().reset();
                }
              },
            ),
          ),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.organizationId,
    required this.onPickCamera,
    required this.onPickGallery,
    required this.onRetry,
    required this.onCandidateSelected,
    required this.onNoneMatch,
  });

  final ProductRecognitionState state;
  final String organizationId;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;
  final VoidCallback onRetry;
  final void Function(ProductRecognitionCandidate candidate)
  onCandidateSelected;
  final VoidCallback onNoneMatch;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case ProductRecognitionStatus.idle:
      case ProductRecognitionStatus.error:
        return _IdlePrompt(
          onPickCamera: onPickCamera,
          onPickGallery: onPickGallery,
        );
      case ProductRecognitionStatus.recognizing:
        return const _LoadingContent();
      case ProductRecognitionStatus.ready:
        final result = state.result;
        if (result == null ||
            result.belowThreshold ||
            result.candidates.isEmpty) {
          return _BelowThresholdContent(onRetry: onRetry);
        }
        return _CandidatesContent(
          result: result,
          feedbackSubmitted: state.feedbackSubmitted,
          onCandidateSelected: onCandidateSelected,
          onNoneMatch: onNoneMatch,
        );
    }
  }
}

class _IdlePrompt extends StatelessWidget {
  const _IdlePrompt({required this.onPickCamera, required this.onPickGallery});

  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(
          Icons.photo_camera_outlined,
          size: 48,
          color: context.colors.outline,
        ),
        const SizedBox(height: AppSpacing.spacing12),
        Text(
          'Tire uma foto do produto (por exemplo, uma peça em uma vitrine) '
          'para identificar candidatos do catálogo. O resultado é sempre '
          'uma lista de sugestões para você confirmar — nunca uma resposta '
          'automática.',
          style: AppTypography.bodyMedium.copyWith(
            color: context.colors.outline,
          ),
        ),
        const SizedBox(height: AppSpacing.spacing16),
        Wrap(
          spacing: AppSpacing.spacing8,
          runSpacing: AppSpacing.spacing8,
          children: <Widget>[
            AppButton(
              label: 'Tirar foto',
              leadingIcon: Icons.camera_alt_outlined,
              onPressed: onPickCamera,
            ),
            AppButton(
              label: 'Escolher da galeria',
              leadingIcon: Icons.photo_library_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: onPickGallery,
            ),
          ],
        ),
      ],
    );
  }
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Analisando a foto...',
          style: AppTypography.titleMedium.copyWith(
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.spacing12),
        const AppSkeleton.line(),
        const SizedBox(height: AppSpacing.spacing8),
        const AppSkeleton.line(),
        const SizedBox(height: AppSpacing.spacing8),
        const AppSkeleton.line(width: 180),
      ],
    );
  }
}

class _BelowThresholdContent extends StatelessWidget {
  const _BelowThresholdContent({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.help_outline, color: context.colors.outline),
            const SizedBox(width: AppSpacing.spacing8),
            Expanded(
              child: Text(
                'Não foi possível identificar este produto com confiança. '
                'Tente novamente com uma foto mais nítida e próxima da peça.',
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

class _CandidatesContent extends StatelessWidget {
  const _CandidatesContent({
    required this.result,
    required this.feedbackSubmitted,
    required this.onCandidateSelected,
    required this.onNoneMatch,
  });

  final ProductRecognitionResult result;
  final bool feedbackSubmitted;
  final void Function(ProductRecognitionCandidate candidate)
  onCandidateSelected;
  final VoidCallback onNoneMatch;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Candidatos encontrados — selecione o produto correto:',
          style: AppTypography.titleMedium.copyWith(
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.spacing12),
        Expanded(
          child: ListView.separated(
            itemCount: result.candidates.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppSpacing.spacing8),
            itemBuilder: (context, index) {
              final candidate = result.candidates[index];
              return _CandidateTile(
                candidate: candidate,
                isDisabled: feedbackSubmitted,
                onTap: () => onCandidateSelected(candidate),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.spacing12),
        AppButton(
          label: 'Nenhum destes',
          leadingIcon: Icons.close,
          variant: AppButtonVariant.text,
          isDisabled: feedbackSubmitted,
          onPressed: onNoneMatch,
        ),
      ],
    );
  }
}

class _CandidateTile extends StatelessWidget {
  const _CandidateTile({
    required this.candidate,
    required this.isDisabled,
    required this.onTap,
  });

  final ProductRecognitionCandidate candidate;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scorePercent = (candidate.score * 100).round();
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(AppRadius.radius12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.spacing8),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.radius12),
          border: Border.all(color: colors.outline.withValues(alpha: 0.16)),
        ),
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.radius8),
              child: SizedBox(
                width: 56,
                height: 56,
                child: candidate.thumbnailUrl != null
                    ? Image.network(
                        candidate.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: colors.surfaceContainer,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: colors.outline,
                          ),
                        ),
                      )
                    : Container(
                        color: colors.surfaceContainer,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.image_outlined,
                          color: colors.outline,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    candidate.productName,
                    style: AppTypography.bodyMedium.copyWith(
                      color: colors.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.spacing4),
                  Text(
                    'Similaridade: $scorePercent%',
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.outline,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.outline),
          ],
        ),
      ),
    );
  }
}
