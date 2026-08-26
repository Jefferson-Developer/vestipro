import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../products/domain/entities/catalog_filter.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/value_objects/variant_availability_status.dart';
import '../../domain/value_objects/catalog_view_mode.dart';
import '../bloc/catalog_filter_bloc.dart';
import '../bloc/catalog_filter_event.dart';
import '../bloc/catalog_filter_state.dart';
import '../widgets/catalog_active_filter_chips.dart';
import '../widgets/catalog_filter_panel.dart';
import '../widgets/catalog_view_mode_selector.dart';

/// The catalog's filterable, multi-view-mode browsing screen (TASK-082,
/// EPIC-10) — grid/lista, coleção, novidades e pronta entrega all reuse the
/// same `AppProductGrid` (TASK-077) through `CatalogFilterBloc`, with a
/// filter panel (bottom sheet on mobile/tablet, permanent side panel on
/// desktop/large desktop, via `AppAdminPageLayout`) and removable active
/// filter chips.
///
/// Scroll position across a push to the product detail and back is
/// preserved two ways, per the task's own requirement: primarily because
/// this page's `BlocProvider`/`Scaffold` simply stay mounted underneath a
/// pushed detail route (same precedent `ProductGridBloc`'s doc already
/// documents), and defensively via [PageStorageKey] in case a caller ever
/// rebuilds this page's subtree instead of pushing on top of it.
class CatalogFilterPage extends StatelessWidget {
  const CatalogFilterPage({
    required this.organizationId,
    required this.createBloc,
    this.companyId,
    this.title = 'Catálogo',
    this.initialViewMode,
    this.initialFilter,
    this.onProductSelected,
    this.onOpenFavorites,
    this.onOpenLookbook,
    this.onUrlStateChanged,
    this.favoriteProductIds,
    this.onFavoriteToggle,
    this.onShareTap,
    super.key,
  });

  final String organizationId;
  final String? companyId;
  final String title;

  /// Seeds the bloc's starting view mode/filter (e.g. from a Flutter Web
  /// deep link's query parameters) — `null` falls back to the last
  /// persisted `CatalogPreferences`. See `CatalogFilterStarted`'s doc.
  final CatalogViewMode? initialViewMode;
  final CatalogFilter? initialFilter;

  final CatalogFilterBloc Function() createBloc;

  final ValueChanged<Product>? onProductSelected;
  final VoidCallback? onOpenFavorites;
  final VoidCallback? onOpenLookbook;

  /// Called on every view mode/filter change so the host can reflect it in
  /// the Flutter Web URL (`context.go(CatalogBrowseRoute(...).location)`),
  /// same "bloc state -> host pushes URL" contract
  /// `CustomerPortfolioPage.onUrlStateChanged` already sets.
  final void Function(CatalogViewMode viewMode, CatalogFilter filter)?
  onUrlStateChanged;

  final Set<String>? favoriteProductIds;
  final void Function(Product product)? onFavoriteToggle;
  final void Function(Product product)? onShareTap;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CatalogFilterBloc>(
      create: (_) => createBloc()
        ..add(
          CatalogFilterStarted(
            organizationId: organizationId,
            companyId: companyId,
            initialViewMode: initialViewMode,
            initialFilter: initialFilter,
          ),
        ),
      child: _CatalogFilterView(
        title: title,
        onProductSelected: onProductSelected,
        onOpenFavorites: onOpenFavorites,
        onOpenLookbook: onOpenLookbook,
        onUrlStateChanged: onUrlStateChanged,
        favoriteProductIds: favoriteProductIds,
        onFavoriteToggle: onFavoriteToggle,
        onShareTap: onShareTap,
      ),
    );
  }
}

class _CatalogFilterView extends StatelessWidget {
  const _CatalogFilterView({
    required this.title,
    this.onProductSelected,
    this.onOpenFavorites,
    this.onOpenLookbook,
    this.onUrlStateChanged,
    this.favoriteProductIds,
    this.onFavoriteToggle,
    this.onShareTap,
  });

  final String title;
  final ValueChanged<Product>? onProductSelected;
  final VoidCallback? onOpenFavorites;
  final VoidCallback? onOpenLookbook;
  final void Function(CatalogViewMode viewMode, CatalogFilter filter)?
  onUrlStateChanged;
  final Set<String>? favoriteProductIds;
  final void Function(Product product)? onFavoriteToggle;
  final void Function(Product product)? onShareTap;

  @override
  Widget build(BuildContext context) {
    return BlocListener<CatalogFilterBloc, CatalogFilterState>(
      listenWhen: (previous, current) =>
          previous.viewMode != current.viewMode ||
          previous.filter != current.filter,
      listener: (context, state) =>
          onUrlStateChanged?.call(state.viewMode, state.filter),
      child: BlocBuilder<CatalogFilterBloc, CatalogFilterState>(
        builder: (context, state) {
          final bloc = context.read<CatalogFilterBloc>();
          return Scaffold(
            body: SafeArea(
              child: AppAdminPageLayout(
                title: title,
                filtersTitle: 'Filtros do catálogo',
                filtersBuilder: (_) => CatalogFilterPanel(
                  state: state,
                  onApply: (filter) => bloc.add(CatalogFilterApplied(filter)),
                  onClear: () =>
                      bloc.add(const CatalogFilterApplied(CatalogFilter.empty)),
                ),
                content: SingleChildScrollView(
                  key: const PageStorageKey<String>('catalog_filter_scroll'),
                  padding: const EdgeInsets.all(AppSpacing.spacing16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      CatalogViewModeSelector(
                        viewMode: state.viewMode,
                        onChanged: (mode) =>
                            bloc.add(CatalogFilterViewModeChanged(mode)),
                        onOpenFavorites: onOpenFavorites,
                        onOpenLookbook: onOpenLookbook,
                      ),
                      const SizedBox(height: AppSpacing.spacing16),
                      CatalogActiveFilterChips(
                        state: state,
                        onRemove: (key, {value}) => bloc.add(
                          CatalogFilterChipRemoved(key, value: value),
                        ),
                      ),
                      if (state.filter.activeCount > 0)
                        const SizedBox(height: AppSpacing.spacing16),
                      _buildContent(context, bloc, state),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    CatalogFilterBloc bloc,
    CatalogFilterState state,
  ) {
    if (state.status == CatalogFilterLoadStatus.unavailable) {
      return const AppEmptyState(
        title: 'Modo indisponível no momento',
        description:
            'Este modo de visualização depende de dados agregados que ainda '
            'não estão disponíveis no VestiPro.',
        icon: Icons.hourglass_empty,
      );
    }

    return AppProductGrid(
      status: _gridStatus(state),
      layout: state.viewMode.isListLayout
          ? AppProductGridLayout.list
          : AppProductGridLayout.grid,
      products: state.products
          .map((product) => _cardDataFor(product, state))
          .toList(growable: false),
      hasMore: state.hasMore,
      isLoadingMore: state.isLoadingMore,
      onLoadMore: () => bloc.add(const CatalogFilterNextPageRequested()),
      emptyTitle: 'Nenhum produto encontrado',
      emptyDescription:
          'Ajuste os filtros ou o modo de visualização para ver outros '
          'produtos do catálogo.',
      errorTitle: 'Não foi possível carregar o catálogo',
      errorMessage: state.failure?.message ?? 'Tente novamente em breve.',
      retryLabel: 'Tentar novamente',
      onRetry: () => bloc.add(const CatalogFilterRetried()),
      onProductTap: (card) {
        final product = state.products.firstWhere((item) => item.id == card.id);
        bloc.add(CatalogFilterProductOpened(product));
        onProductSelected?.call(product);
      },
    );
  }

  AppProductGridStatus _gridStatus(CatalogFilterState state) {
    return switch (state.status) {
      CatalogFilterLoadStatus.initial ||
      CatalogFilterLoadStatus.loading => AppProductGridStatus.loading,
      CatalogFilterLoadStatus.failure => AppProductGridStatus.error,
      CatalogFilterLoadStatus.empty => AppProductGridStatus.empty,
      CatalogFilterLoadStatus.success ||
      CatalogFilterLoadStatus.unavailable => AppProductGridStatus.idle,
    };
  }

  AppProductCardData _cardDataFor(Product product, CatalogFilterState state) {
    final principalPhoto = product.principalPhoto;
    final imageUrl = principalPhoto?.thumbnailUrl ?? principalPhoto?.url;
    final availability = state.availabilityByProductId[product.id];
    return AppProductCardData(
      id: product.id,
      name: product.name,
      brandOrCollection: product.brand,
      imageUrl: imageUrl,
      availability: _availabilityFor(availability?.status),
      availabilityLabel: availability == null
          ? null
          : _availabilityLabelFor(availability.status),
      badgeLabels: <String>[if (product.tags.isNotEmpty) product.tags.first],
      isFavorite: favoriteProductIds?.contains(product.id) ?? false,
      onFavoriteTap: onFavoriteToggle == null
          ? null
          : () => onFavoriteToggle!(product),
      onShareTap: onShareTap == null ? null : () => onShareTap!(product),
    );
  }

  AppProductAvailability _availabilityFor(VariantAvailabilityStatus? status) {
    return switch (status ?? VariantAvailabilityStatus.readyStock) {
      VariantAvailabilityStatus.readyStock => AppProductAvailability.readyStock,
      VariantAvailabilityStatus.futureStock =>
        AppProductAvailability.futureStock,
      VariantAvailabilityStatus.unavailable =>
        AppProductAvailability.unavailable,
    };
  }

  String _availabilityLabelFor(VariantAvailabilityStatus status) {
    return switch (status) {
      VariantAvailabilityStatus.readyStock => 'Pronta entrega',
      VariantAvailabilityStatus.futureStock => 'Estoque futuro',
      VariantAvailabilityStatus.unavailable => 'Indisponível',
    };
  }
}
