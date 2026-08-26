import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/value_objects/catalog_view_mode.dart';

/// The horizontal switcher between every `CatalogViewMode` (TASK-082).
///
/// `favorites`/`lookbook` never dispatch [onChanged] — they call
/// [onOpenFavorites]/[onOpenLookbook] instead, navigating to the
/// already-built `FavoritesPage`/`LookbookPage` rather than asking
/// `CatalogFilterBloc` to duplicate them (see `CatalogViewMode`'s doc).
/// `byCollection`/`byCampaign` are intentionally absent from this generic
/// switcher — they are only reached with a specific collection/campaign
/// already chosen (e.g. tapping a collection banner elsewhere), which this
/// mode-agnostic control has no "which one" context for.
class CatalogViewModeSelector extends StatelessWidget {
  const CatalogViewModeSelector({
    required this.viewMode,
    required this.onChanged,
    this.onOpenFavorites,
    this.onOpenLookbook,
    super.key,
  });

  final CatalogViewMode viewMode;
  final ValueChanged<CatalogViewMode> onChanged;
  final VoidCallback? onOpenFavorites;
  final VoidCallback? onOpenLookbook;

  static const _labels = <CatalogViewMode, String>{
    CatalogViewMode.grid: 'Grade',
    CatalogViewMode.list: 'Lista',
    CatalogViewMode.newArrivals: 'Novidades',
    CatalogViewMode.bestSellers: 'Mais vendidos',
    CatalogViewMode.recommended: 'Recomendados',
    CatalogViewMode.readyStock: 'Pronta entrega',
    CatalogViewMode.favorites: 'Favoritos',
    CatalogViewMode.lookbook: 'Lookbook',
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          for (final mode in _labels.keys) ...<Widget>[
            AppFilterChip(
              label: _labels[mode]!,
              selected: viewMode == mode,
              onSelected: (_) => _select(mode),
            ),
            const SizedBox(width: AppSpacing.spacing8),
          ],
        ],
      ),
    );
  }

  void _select(CatalogViewMode mode) {
    if (mode == CatalogViewMode.favorites && onOpenFavorites != null) {
      onOpenFavorites!();
      return;
    }
    if (mode == CatalogViewMode.lookbook && onOpenLookbook != null) {
      onOpenLookbook!();
      return;
    }
    onChanged(mode);
  }
}
