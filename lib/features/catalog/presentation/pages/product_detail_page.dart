import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../pricing/domain/entities/resolved_variant_price.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/product_color.dart';
import '../../../products/domain/entities/variant_availability.dart';
import '../../../products/domain/value_objects/variant_availability_status.dart';
import '../bloc/product_detail_bloc.dart';
import '../bloc/product_detail_event.dart';
import '../bloc/product_detail_state.dart';
import '../widgets/product_detail_gallery.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({
    required this.organizationId,
    required this.productId,
    required this.createBloc,
    this.origin = 'grid',
    this.onAddToOrder,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.onSharePressed,
    super.key,
  });

  final String organizationId;
  final String productId;
  final String origin;
  final ProductDetailBloc Function() createBloc;
  final void Function(Product product, List<ProductDetailOrderLine> lines)?
  onAddToOrder;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onSharePressed;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProductDetailBloc>(
      create: (_) => createBloc()
        ..add(
          ProductDetailStarted(
            organizationId: organizationId,
            productId: productId,
            origin: origin,
          ),
        ),
      child: _ProductDetailView(
        onAddToOrder: onAddToOrder,
        isFavorite: isFavorite,
        onFavoriteToggle: onFavoriteToggle,
        onSharePressed: onSharePressed,
      ),
    );
  }
}

class _ProductDetailView extends StatelessWidget {
  const _ProductDetailView({
    this.onAddToOrder,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.onSharePressed,
  });

  final void Function(Product product, List<ProductDetailOrderLine> lines)?
  onAddToOrder;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onSharePressed;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductDetailBloc, ProductDetailState>(
      builder: (context, state) {
        final bloc = context.read<ProductDetailBloc>();
        return Scaffold(
          appBar: AppBar(
            title: Text(state.product?.name ?? 'Produto'),
            actions: <Widget>[
              if (onSharePressed != null)
                AppIconButton(
                  icon: Icons.share_outlined,
                  semanticLabel: 'Compartilhar produto',
                  onPressed: onSharePressed,
                ),
              if (onFavoriteToggle != null)
                AppIconButton(
                  icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                  semanticLabel: isFavorite
                      ? 'Remover dos favoritos'
                      : 'Adicionar aos favoritos',
                  onPressed: onFavoriteToggle,
                ),
            ],
          ),
          body: SafeArea(child: _buildBody(context, bloc, state)),
          bottomNavigationBar: state.status == ProductDetailLoadStatus.success
              ? _AddToOrderBar(state: state, onAddToOrder: onAddToOrder)
              : null,
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    ProductDetailBloc bloc,
    ProductDetailState state,
  ) {
    return switch (state.status) {
      ProductDetailLoadStatus.initial ||
      ProductDetailLoadStatus.loading => const _LoadingView(),
      ProductDetailLoadStatus.failure => AppErrorState(
        title: 'Não foi possível carregar o produto',
        message: state.failure?.message ?? 'Tente novamente em breve.',
        retryLabel: 'Tentar novamente',
        onRetry: () => bloc.add(const ProductDetailRetried()),
      ),
      ProductDetailLoadStatus.success => _ProductDetailContent(state: state),
    };
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppSkeleton.block(height: 360),
          SizedBox(height: AppSpacing.spacing16),
          AppSkeleton.line(),
          SizedBox(height: AppSpacing.spacing8),
          AppSkeleton.line(width: 180),
          SizedBox(height: AppSpacing.spacing24),
          AppSkeleton.block(height: 220),
        ],
      ),
    );
  }
}

class _ProductDetailContent extends StatelessWidget {
  const _ProductDetailContent({required this.state});

  final ProductDetailState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final product = state.product;
    if (product == null) return const SizedBox.shrink();
    final bloc = context.read<ProductDetailBloc>();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ProductDetailGallery(photos: state.galleryPhotos),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (product.brand != null) ...<Widget>[
                  Text(
                    product.brand!,
                    style: AppTypography.labelMedium.copyWith(
                      color: colors.outline,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacing4),
                ],
                Text(
                  product.name,
                  style: AppTypography.titleLarge.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing4),
                Text(
                  'Ref. ${product.reference}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.outline,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing12),
                _PriceStatusBadge(state: state),
                if (state.hasPricingWarning) ...<Widget>[
                  const SizedBox(height: AppSpacing.spacing8),
                  const AppStatusBadge(
                    label:
                        'Não foi possível confirmar todos os preços agora. '
                        'Exibindo os preços resolvidos localmente.',
                    variant: AppStatusBadgeVariant.warning,
                    icon: Icons.sell_outlined,
                  ),
                ],
                if (state.hasAvailabilityWarning) ...<Widget>[
                  const SizedBox(height: AppSpacing.spacing8),
                  const AppStatusBadge(
                    label:
                        'Não foi possível confirmar a disponibilidade agora. '
                        'Exibindo os últimos dados salvos.',
                    variant: AppStatusBadgeVariant.warning,
                    icon: Icons.cloud_off_outlined,
                  ),
                ],
                const SizedBox(height: AppSpacing.spacing20),
                if (state.colorOptions.isNotEmpty) ...<Widget>[
                  Text(
                    'Cor',
                    style: AppTypography.titleMedium.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacing8),
                  AppColorSwatchSelector(
                    options: state.colorOptions
                        .map((option) => _swatchOptionFor(state, option))
                        .toList(growable: false),
                    selectedId: state.selectedColorId,
                    onSelected: (option) => bloc.add(
                      ProductDetailColorSelected(option.id as String),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacing20),
                ],
                Text(
                  'Grade de tamanhos',
                  style: AppTypography.titleMedium.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing8),
                _buildSizeGrid(context, bloc, state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  AppColorSwatchOption _swatchOptionFor(
    ProductDetailState state,
    ProductDetailColorOption option,
  ) {
    return AppColorSwatchOption(
      id: option.id,
      label: option.label,
      color: _colorFromHex(option.color),
      availability: _swatchAvailabilityFor(
        state.availabilityForColor(option.id),
      ),
    );
  }

  Widget _buildSizeGrid(
    BuildContext context,
    ProductDetailBloc bloc,
    ProductDetailState state,
  ) {
    final selectedColorId = state.selectedColorId;
    if (selectedColorId == null || state.orderedSizes.isEmpty) {
      return const AppEmptyState(
        icon: Icons.grid_on_outlined,
        title: 'Grade indisponível',
        description:
            'Este produto ainda não tem tamanhos/variantes ativos para venda.',
      );
    }

    final columns = state.orderedSizes
        .map((size) => AppSizeGridColumn(id: size.id, label: size.label))
        .toList(growable: false);
    final cells = <Object, AppSizeGridCell>{};
    for (final size in state.orderedSizes) {
      final variant = state.variantForCell(
        colorId: selectedColorId,
        sizeId: size.id,
      );
      if (variant == null) continue;
      final availability = state.availabilityForVariant(variant);
      final price = state.priceForVariant(variant);
      cells[size.id] = AppSizeGridCell(
        quantity: state.quantityForVariant(variant),
        availability: _cellAvailabilityFor(availability.status, price),
        availabilityLabel: _availabilityLabelFor(availability, price),
      );
    }

    if (cells.isEmpty) {
      return const AppEmptyState(
        icon: Icons.grid_on_outlined,
        title: 'Grade indisponível',
        description: 'Nenhum tamanho ativo para esta cor.',
      );
    }

    final selectedColor = state.colorOptions.firstWhere(
      (option) => option.id == selectedColorId,
    );

    return AppSizeGrid(
      columns: columns,
      rows: <AppSizeGridRow>[
        AppSizeGridRow(
          id: selectedColorId,
          label: selectedColor.label,
          colorSwatch: _colorFromHex(selectedColor.color),
          cells: cells,
        ),
      ],
      onQuantityChanged: (rowId, columnId, quantity) {
        bloc.add(
          ProductDetailQuantityChanged(
            colorId: rowId as String,
            sizeId: columnId as String,
            quantity: quantity,
          ),
        );
      },
    );
  }

  AppColorAvailability _swatchAvailabilityFor(
    VariantAvailabilityStatus status,
  ) {
    return switch (status) {
      VariantAvailabilityStatus.readyStock => AppColorAvailability.readyStock,
      VariantAvailabilityStatus.futureStock => AppColorAvailability.futureStock,
      VariantAvailabilityStatus.unavailable => AppColorAvailability.unavailable,
    };
  }

  AppSizeGridCellAvailability _cellAvailabilityFor(
    VariantAvailabilityStatus status,
    ResolvedVariantPrice? price,
  ) {
    if (!(price?.hasPrice ?? false)) {
      return AppSizeGridCellAvailability.unavailable;
    }
    return switch (status) {
      VariantAvailabilityStatus.readyStock =>
        AppSizeGridCellAvailability.readyStock,
      VariantAvailabilityStatus.futureStock =>
        AppSizeGridCellAvailability.futureStock,
      VariantAvailabilityStatus.unavailable =>
        AppSizeGridCellAvailability.unavailable,
    };
  }

  String _availabilityLabelFor(
    VariantAvailability availability,
    ResolvedVariantPrice? price,
  ) {
    if (!(price?.hasPrice ?? false)) {
      return 'Sem preço definido na tabela ativa';
    }
    final stockLabel = switch (availability.status) {
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
    return '${_formatPrice(price!.price!)} · $stockLabel';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _formatPrice(double value) {
    return NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    ).format(value);
  }

  Color _colorFromHex(ProductColor? color) {
    if (color == null) return const Color(0xFFBDBDBD);
    final value = color.hex.value;
    return Color(0xFF000000 | int.parse(value.substring(1), radix: 16));
  }
}

class _PriceStatusBadge extends StatelessWidget {
  const _PriceStatusBadge({required this.state});

  final ProductDetailState state;

  @override
  Widget build(BuildContext context) {
    final price = state.lowestResolvedPrice;
    if (price == null) {
      return const AppStatusBadge(
        label: 'Sem preço definido na tabela ativa',
        variant: AppStatusBadgeVariant.warning,
        icon: Icons.sell_outlined,
      );
    }
    final formatted = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    ).format(price);
    final hasVariantException = state.pricesByVariantId.values.any(
      (item) => item.isVariantException,
    );
    return AppStatusBadge(
      label: hasVariantException ? 'A partir de $formatted' : formatted,
      variant: AppStatusBadgeVariant.success,
      icon: Icons.sell_outlined,
    );
  }
}

class _AddToOrderBar extends StatelessWidget {
  const _AddToOrderBar({required this.state, this.onAddToOrder});

  final ProductDetailState state;
  final void Function(Product product, List<ProductDetailOrderLine> lines)?
  onAddToOrder;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final total = state.totalQuantity;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.outline.withValues(alpha: 0.24)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spacing16),
          child: AppButton(
            label: total > 0
                ? 'Adicionar ao pedido ($total ${total == 1 ? 'item' : 'itens'})'
                : 'Adicionar ao pedido',
            leadingIcon: Icons.add_shopping_cart_outlined,
            expand: true,
            isDisabled: total == 0,
            onPressed: total == 0
                ? null
                : () {
                    final product = state.product;
                    if (product == null) return;
                    context.read<ProductDetailBloc>().add(
                      const ProductDetailAddToOrderRequested(),
                    );
                    onAddToOrder?.call(product, state.orderLines);
                  },
          ),
        ),
      ),
    );
  }
}
