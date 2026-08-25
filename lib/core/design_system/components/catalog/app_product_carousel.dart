import 'package:flutter/material.dart';

import '../../foundations/foundations.dart';
import 'app_product_grid.dart';

/// A horizontally-scrollable row of product cards (TASK-076), reusing the
/// exact same [AppProductCard]/[AppProductCardSkeleton] [AppProductGrid]
/// renders — the catalog home's "carrosséis horizontais" (coleções em
/// destaque, lançamentos, campanhas) reuse this instead of a page-specific
/// card, per TASK-076's own "não criar um card de produto alternativo"
/// rule.
///
/// Unlike [AppProductGrid], this widget never shows an empty/error state
/// itself: a carousel with no [products] renders nothing (an empty
/// [SizedBox]) — the caller (`CatalogHomeSectionView`) is the one that
/// decides whether an empty/failed section should render at all, never this
/// generic building block.
class AppProductCarousel extends StatelessWidget {
  const AppProductCarousel({
    required this.products,
    required this.onProductTap,
    this.isLoading = false,
    this.loadingItemCount = 4,
    this.cardWidth = 168,
    this.readyStockLabel = 'Pronta entrega',
    this.futureStockLabel = 'Estoque futuro',
    this.unavailableLabel = 'Indisponível',
    super.key,
  });

  final List<AppProductCardData> products;
  final ValueChanged<AppProductCardData> onProductTap;
  final bool isLoading;
  final int loadingItemCount;
  final double cardWidth;

  final String readyStockLabel;
  final String futureStockLabel;
  final String unavailableLabel;

  @override
  Widget build(BuildContext context) {
    final itemCount = isLoading ? loadingItemCount : products.length;
    if (itemCount == 0) return const SizedBox.shrink();

    return SizedBox(
      height: cardWidth * 1.85,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.spacing12),
        itemBuilder: (context, index) {
          if (isLoading) {
            return SizedBox(
              width: cardWidth,
              child: const AppProductCardSkeleton(),
            );
          }
          final product = products[index];
          return SizedBox(
            width: cardWidth,
            child: AppProductCard(
              product: product,
              onTap: () => onProductTap(product),
              readyStockLabel: readyStockLabel,
              futureStockLabel: futureStockLabel,
              unavailableLabel: unavailableLabel,
            ),
          );
        },
      ),
    );
  }
}
