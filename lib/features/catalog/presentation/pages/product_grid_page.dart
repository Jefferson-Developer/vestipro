import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/variant_availability.dart';
import '../../../products/domain/value_objects/variant_availability_status.dart';
import '../bloc/product_grid_bloc.dart';
import '../bloc/product_grid_event.dart';
import '../bloc/product_grid_state.dart';

/// The catalog's full visual grid (TASK-077, EPIC-10) — a continuously
/// scrollable, cursor-paginated listing of every active Product, the screen
/// "ver todos os lançamentos"/busca/coleção/campanha/favoritos link into.
///
/// Price is intentionally never shown here: no price-list/pricing-engine
/// implementation exists yet (EPIC-11), and this screen never fabricates or
/// caches a price client-side — `AppProductCardData.priceLabel` is simply
/// left `null`, which `AppProductCard` already renders as "no price row" by
/// design, exactly like `ProductSearchPage` does today.
class ProductGridPage extends StatelessWidget {
  const ProductGridPage({
    required this.organizationId,
    required this.createBloc,
    this.companyId,
    this.title = 'Catálogo',
    this.onProductSelected,
    this.favoriteProductIds,
    this.onFavoriteToggle,
    this.onShareTap,
    super.key,
  });

  final String organizationId;
  final String? companyId;
  final String title;
  final ProductGridBloc Function() createBloc;

  /// Called after the tap is logged as `product_viewed` — routing to the
  /// product detail (TASK-078) is decided by whoever instantiates this page,
  /// never by the page itself.
  final ValueChanged<Product>? onProductSelected;

  /// Every currently favorited `Product.id` (TASK-079), or `null` to hide
  /// the favorite button entirely — this page never depends on the
  /// favorites feature itself, the caller (which already watches
  /// `FavoriteStatusCubit`) owns that state, same "host decides" contract
  /// [onProductSelected] already has.
  final Set<String>? favoriteProductIds;

  /// Called when a card's favorite button is tapped — `null` (the default)
  /// keeps every card exactly as it rendered before TASK-079.
  final void Function(Product product)? onFavoriteToggle;

  /// Called when a card's share button is tapped (TASK-081) — `null` (the
  /// default) hides the button and keeps every card exactly as it rendered
  /// before. Opening the actual share sheet (`CatalogShareSheet`) is decided
  /// by whoever hosts this page, same "host decides" contract
  /// [onFavoriteToggle]/[onProductSelected] already set.
  final void Function(Product product)? onShareTap;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProductGridBloc>(
      create: (_) => createBloc()
        ..add(
          ProductGridStarted(
            organizationId: organizationId,
            companyId: companyId,
          ),
        ),
      child: _ProductGridView(
        title: title,
        onProductSelected: onProductSelected,
        favoriteProductIds: favoriteProductIds,
        onFavoriteToggle: onFavoriteToggle,
        onShareTap: onShareTap,
      ),
    );
  }
}

class _ProductGridView extends StatelessWidget {
  const _ProductGridView({
    required this.title,
    this.onProductSelected,
    this.favoriteProductIds,
    this.onFavoriteToggle,
    this.onShareTap,
  });

  final String title;
  final ValueChanged<Product>? onProductSelected;
  final Set<String>? favoriteProductIds;
  final void Function(Product product)? onFavoriteToggle;
  final void Function(Product product)? onShareTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: BlocBuilder<ProductGridBloc, ProductGridState>(
          builder: (context, state) {
            final bloc = context.read<ProductGridBloc>();
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.spacing16),
              child: AppProductGrid(
                status: _gridStatus(state),
                products: state.products
                    .map((product) => _cardDataFor(product, state))
                    .toList(growable: false),
                hasMore: state.hasMore,
                isLoadingMore: state.isLoadingMore,
                onLoadMore: () =>
                    bloc.add(const ProductGridNextPageRequested()),
                emptyTitle: 'Nenhum produto encontrado',
                emptyDescription:
                    'Assim que houver produtos ativos no catálogo, eles '
                    'aparecem aqui.',
                errorTitle: 'Não foi possível carregar o catálogo',
                errorMessage:
                    state.failure?.message ?? 'Tente novamente em breve.',
                retryLabel: 'Tentar novamente',
                onRetry: () => bloc.add(const ProductGridRetried()),
                onProductTap: (card) {
                  final product = state.products.firstWhere(
                    (item) => item.id == card.id,
                  );
                  bloc.add(ProductGridProductOpened(product));
                  onProductSelected?.call(product);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  AppProductGridStatus _gridStatus(ProductGridState state) {
    return switch (state.status) {
      ProductGridLoadStatus.initial ||
      ProductGridLoadStatus.loading => AppProductGridStatus.loading,
      ProductGridLoadStatus.failure => AppProductGridStatus.error,
      ProductGridLoadStatus.empty => AppProductGridStatus.empty,
      ProductGridLoadStatus.success => AppProductGridStatus.idle,
    };
  }

  AppProductCardData _cardDataFor(Product product, ProductGridState state) {
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
          : _availabilityLabelFor(availability),
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

  String _availabilityLabelFor(VariantAvailability availability) {
    return switch (availability.status) {
      VariantAvailabilityStatus.readyStock =>
        availability.availableQuantity == null
            ? 'Pronta entrega'
            : 'Pronta entrega: ${availability.availableQuantity}',
      VariantAvailabilityStatus.futureStock =>
        availability.futureAvailableAt == null
            ? 'Estoque futuro'
            : 'Estoque futuro ${_formatDate(availability.futureAvailableAt!)}',
      VariantAvailabilityStatus.unavailable => 'Indisponível',
    };
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
