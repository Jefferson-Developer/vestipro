import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/value_objects/variant_availability_status.dart';
import '../bloc/favorites_bloc.dart';
import '../bloc/favorites_event.dart';
import '../bloc/favorites_state.dart';
import '../cubit/favorite_status_cubit.dart';
import '../cubit/favorite_status_state.dart';

/// "Favoritos" (TASK-079, EPIC-10) — the products the signed-in
/// representative saved for later consultation during a visit or
/// negotiation, rendered through the exact same `AppProductGrid` (TASK-077)
/// the full catalog grid uses, never a duplicated card component.
///
/// [FavoriteStatusCubit] is this screen's own reactive "which of these are
/// still favorited" source: unfavoriting a card here removes it from the
/// grid immediately (its id drops out of the cubit's set) without waiting
/// for `FavoritesBloc` to re-fetch, exactly the optimistic feel TASK-079
/// requires.
class FavoritesPage extends StatelessWidget {
  const FavoritesPage({
    required this.organizationId,
    required this.createFavoritesBloc,
    required this.createFavoriteStatusCubit,
    this.companyId,
    this.title = 'Favoritos',
    this.onProductSelected,
    super.key,
  });

  final String organizationId;
  final String? companyId;
  final String title;
  final FavoritesBloc Function() createFavoritesBloc;
  final FavoriteStatusCubit Function() createFavoriteStatusCubit;

  /// Called after the tap is logged as `product_viewed` — routing to the
  /// product detail is decided by whoever instantiates this page, same
  /// contract as `ProductGridPage.onProductSelected`.
  final ValueChanged<Product>? onProductSelected;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<FavoritesBloc>(
          create: (_) => createFavoritesBloc()
            ..add(
              FavoritesStarted(
                organizationId: organizationId,
                companyId: companyId,
              ),
            ),
        ),
        BlocProvider<FavoriteStatusCubit>(
          create: (_) =>
              createFavoriteStatusCubit()
                ..start(organizationId: organizationId, companyId: companyId),
        ),
      ],
      child: _FavoritesView(title: title, onProductSelected: onProductSelected),
    );
  }
}

class _FavoritesView extends StatelessWidget {
  const _FavoritesView({required this.title, this.onProductSelected});

  final String title;
  final ValueChanged<Product>? onProductSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: BlocBuilder<FavoritesBloc, FavoritesState>(
          builder: (context, favoritesState) {
            return BlocBuilder<FavoriteStatusCubit, FavoriteStatusState>(
              builder: (context, favoriteStatusState) {
                final bloc = context.read<FavoritesBloc>();
                final favoriteStatusCubit = context.read<FavoriteStatusCubit>();

                // A card only stays on screen while its id is still in the
                // reactive favorited set — this is what makes tapping the
                // (already-filled) heart on this very screen remove the
                // card immediately, without `FavoritesBloc` re-fetching.
                final visibleProducts = favoritesState.products
                    .where(
                      (product) => favoriteStatusState.isFavorite(product.id),
                    )
                    .toList(growable: false);

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.spacing16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      if (favoritesState.unavailableCount > 0) ...<Widget>[
                        AppStatusBadge(
                          label: favoritesState.unavailableCount == 1
                              ? '1 favorito não está mais disponível e foi '
                                    'ocultado.'
                              : '${favoritesState.unavailableCount} '
                                    'favoritos não estão mais disponíveis e '
                                    'foram ocultados.',
                          variant: AppStatusBadgeVariant.warning,
                          icon: Icons.info_outline,
                        ),
                        const SizedBox(height: AppSpacing.spacing16),
                      ],
                      AppProductGrid(
                        status: _gridStatus(favoritesState, visibleProducts),
                        products: visibleProducts
                            .map(
                              (product) => _cardDataFor(
                                product,
                                favoritesState,
                                onFavoriteTap: () => favoriteStatusCubit.toggle(
                                  productId: product.id,
                                  source: 'favorites',
                                ),
                              ),
                            )
                            .toList(growable: false),
                        hasMore: favoritesState.hasMore,
                        isLoadingMore: favoritesState.isLoadingMore,
                        onLoadMore: () =>
                            bloc.add(const FavoritesNextPageRequested()),
                        emptyTitle: 'Nenhum favorito ainda',
                        emptyDescription:
                            'Toque no coração de um produto no catálogo para '
                            'salvá-lo aqui e consultar depois durante uma '
                            'visita ou negociação.',
                        errorTitle: 'Não foi possível carregar seus favoritos',
                        errorMessage:
                            favoritesState.failure?.message ??
                            'Tente novamente em breve.',
                        retryLabel: 'Tentar novamente',
                        onRetry: () => bloc.add(const FavoritesRetried()),
                        onProductTap: (card) {
                          final product = visibleProducts.firstWhere(
                            (item) => item.id == card.id,
                          );
                          bloc.add(FavoritesProductOpened(product));
                          onProductSelected?.call(product);
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  AppProductGridStatus _gridStatus(
    FavoritesState state,
    List<Product> visibleProducts,
  ) {
    if (state.status == FavoritesLoadStatus.initial ||
        state.status == FavoritesLoadStatus.loading) {
      return AppProductGridStatus.loading;
    }
    if (state.status == FavoritesLoadStatus.failure) {
      return AppProductGridStatus.error;
    }
    // Every favorite loaded may have been individually unfavorited from
    // this very screen since the last fetch — the empty state must reflect
    // the currently *visible* set, not just `FavoritesState.status`.
    return visibleProducts.isEmpty
        ? AppProductGridStatus.empty
        : AppProductGridStatus.idle;
  }

  AppProductCardData _cardDataFor(
    Product product,
    FavoritesState state, {
    required VoidCallback onFavoriteTap,
  }) {
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
      isFavorite: true,
      onFavoriteTap: onFavoriteTap,
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
