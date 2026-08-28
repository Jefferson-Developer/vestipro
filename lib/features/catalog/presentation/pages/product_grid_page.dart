import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/variant_availability.dart';
import '../../../products/domain/value_objects/variant_availability_status.dart';
import '../bloc/product_grid_bloc.dart';
import '../bloc/product_grid_event.dart';
import '../bloc/product_grid_state.dart';

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
  final ValueChanged<Product>? onProductSelected;
  final Set<String>? favoriteProductIds;
  final void Function(Product product)? onFavoriteToggle;
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
    final badges = <String>[
      if (product.tags.isNotEmpty) product.tags.first,
      if (state.unpricedProductIds.contains(product.id)) 'Sem preço',
    ];
    return AppProductCardData(
      id: product.id,
      name: product.name,
      brandOrCollection: product.brand,
      imageUrl: imageUrl,
      priceLabel: state.priceLabelsByProductId[product.id],
      availability: _availabilityFor(availability?.status),
      availabilityLabel: availability == null
          ? null
          : _availabilityLabelFor(availability),
      badgeLabels: badges,
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
      VariantAvailabilityStatus.futureStock => _futureStockLabel(availability),
      VariantAvailabilityStatus.unavailable => 'Indisponível',
    };
  }

  String _futureStockLabel(VariantAvailability availability) {
    final quantityLabel = availability.futureAvailableQuantity == null
        ? 'Estoque futuro'
        : 'Previsão: ${availability.futureAvailableQuantity} un.';
    if (availability.futureAvailableAt == null) {
      return quantityLabel;
    }
    final formattedDate = DateFormat.yMd(Intl.getCurrentLocale()).format(
      DateTime(
        availability.futureAvailableAt!.year,
        availability.futureAvailableAt!.month,
        availability.futureAvailableAt!.day,
      ),
    );
    return '$quantityLabel em $formattedDate';
  }
}
