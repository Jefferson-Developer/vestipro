import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/catalog_home_item.dart';
import '../../domain/entities/catalog_home_section.dart';

/// Renders one already-resolved [CatalogHomeSection] as a title + horizontal
/// carousel (TASK-076), reusing [AppProductCarousel]/[AppProductCardData] —
/// the Design System's product grid/card, never a home-specific card.
///
/// Never called for an empty section: `CatalogHomeBloc` already drops empty
/// sections from `CatalogHomeState.sections`, so this widget does not need
/// (and does not implement) its own empty state.
class CatalogHomeSectionView extends StatelessWidget {
  const CatalogHomeSectionView({
    required this.section,
    required this.onItemTap,
    super.key,
  });

  final CatalogHomeSection section;
  final ValueChanged<CatalogHomeItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
          child: Text(
            section.title,
            style: AppTypography.titleMedium.copyWith(color: colors.onSurface),
          ),
        ),
        const SizedBox(height: AppSpacing.spacing12),
        AppProductCarousel(
          products: section.items.map(_toCardData).toList(growable: false),
          onProductTap: (card) {
            final item = section.items.firstWhere(
              (candidate) => candidate.id == card.id,
            );
            onItemTap(item);
          },
        ),
      ],
    );
  }

  AppProductCardData _toCardData(CatalogHomeItem item) {
    return AppProductCardData(
      id: item.id,
      name: item.title,
      brandOrCollection: item.subtitle,
      imageUrl: item.imageUrl,
      badgeLabels: item.badgeLabel == null
          ? const <String>[]
          : <String>[item.badgeLabel!],
    );
  }
}
