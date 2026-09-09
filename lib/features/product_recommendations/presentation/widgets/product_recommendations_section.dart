import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/product_recommendation.dart';
import '../../domain/entities/product_recommendation_item.dart';
import '../bloc/product_recommendations_bloc.dart';
import '../bloc/product_recommendations_event.dart';
import '../bloc/product_recommendations_state.dart';

/// Renders the current `ProductRecommendation` for whichever scope the
/// enclosing `BlocProvider<ProductRecommendationsBloc>` was started with
/// (TASK-190, EPIC-28) — used both by the catalog (grid/detalhe de produto,
/// `product` scope) and by the tela do cliente (`customer` scope).
///
/// Every state (loading/failure/no data yet/insufficient data/ready) is
/// rendered explicitly — a recommendation is never silently hidden without
/// an explanation (`tasks.md`/TASK-190's own fallback rule), and every item
/// always shows its [ProductRecommendationItem.reasonLabel] alongside the
/// product name, never a bare suggestion without justification.
class ProductRecommendationsSection extends StatelessWidget {
  const ProductRecommendationsSection({
    required this.title,
    this.onProductTap,
    super.key,
  });

  final String title;
  final void Function(String productId)? onProductTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductRecommendationsBloc, ProductRecommendationsState>(
      builder: (context, state) {
        return switch (state.loadStatus) {
          ProductRecommendationsLoadStatus.initial ||
          ProductRecommendationsLoadStatus.loading => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.spacing16),
            child: Center(child: CircularProgressIndicator()),
          ),
          ProductRecommendationsLoadStatus.failure => AppEmptyState(
            icon: Icons.error_outline,
            title: 'Não foi possível carregar as recomendações',
            description: state.failure?.message ?? 'Tente novamente em breve.',
            actionLabel: 'Tentar novamente',
            onAction: () => context.read<ProductRecommendationsBloc>().add(
              const ProductRecommendationsRefreshRequested(),
            ),
          ),
          ProductRecommendationsLoadStatus.ready => _ReadyContent(
            title: title,
            recommendation: state.recommendation,
            onProductTap: onProductTap,
          ),
        };
      },
    );
  }
}

class _ReadyContent extends StatelessWidget {
  const _ReadyContent({
    required this.title,
    required this.recommendation,
    this.onProductTap,
  });

  final String title;
  final ProductRecommendation? recommendation;
  final void Function(String productId)? onProductTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final current = recommendation;

    if (current == null || current.insufficientData) {
      return AppEmptyState(
        icon: Icons.auto_awesome_outlined,
        title: 'Sem recomendações por enquanto',
        description: current == null
            ? 'Ainda não há uma recomendação gerada para este contexto.'
            : 'Ainda não há histórico de compras suficiente para gerar uma '
                  'recomendação — nenhuma sugestão é inventada nessa condição.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: AppTypography.titleMedium.copyWith(color: colors.onSurface),
        ),
        if (current.fallbackApplied) ...<Widget>[
          const SizedBox(height: AppSpacing.spacing4),
          Text(
            'Ainda não há histórico suficiente para uma recomendação '
            'personalizada — mostrando os produtos mais vendidos da empresa.',
            style: AppTypography.bodySmall.copyWith(color: colors.outline),
          ),
        ],
        const SizedBox(height: AppSpacing.spacing12),
        for (final item in current.items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.spacing8),
            child: _RecommendationTile(item: item, onTap: onProductTap),
          ),
      ],
    );
  }
}

class _RecommendationTile extends StatelessWidget {
  const _RecommendationTile({required this.item, this.onTap});

  final ProductRecommendationItem item;
  final void Function(String productId)? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.radius12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.radius12),
        onTap: onTap == null ? null : () => onTap!(item.productId),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.spacing12),
          decoration: BoxDecoration(
            border: Border.all(color: colors.outline.withValues(alpha: 0.24)),
            borderRadius: BorderRadius.circular(AppRadius.radius12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                item.productName,
                style: AppTypography.labelLarge.copyWith(
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.spacing4),
              Text(
                item.reasonLabel,
                style: AppTypography.bodySmall.copyWith(color: colors.outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
