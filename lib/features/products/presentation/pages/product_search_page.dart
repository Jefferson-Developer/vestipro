import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_search_source.dart';
import '../../domain/entities/variant_availability.dart';
import '../../domain/value_objects/variant_availability_status.dart';
import '../bloc/product_search_bloc.dart';
import '../bloc/product_search_event.dart';
import '../bloc/product_search_state.dart';

class ProductSearchPage extends StatelessWidget {
  const ProductSearchPage({
    required this.organizationId,
    required this.createBloc,
    this.initialQuery = '',
    this.initialSource = ProductSearchSource.remote,
    this.onProductSelected,
    super.key,
  });

  final String organizationId;
  final String initialQuery;
  final ProductSearchSource initialSource;
  final ProductSearchBloc Function() createBloc;
  final ValueChanged<Product>? onProductSelected;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProductSearchBloc>(
      create: (_) => createBloc()
        ..add(
          ProductSearchStarted(
            organizationId: organizationId,
            initialQuery: initialQuery,
            source: initialSource,
          ),
        ),
      child: _ProductSearchView(onProductSelected: onProductSelected),
    );
  }
}

class _ProductSearchView extends StatelessWidget {
  const _ProductSearchView({this.onProductSelected});

  final ValueChanged<Product>? onProductSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<ProductSearchBloc, ProductSearchState>(
        builder: (context, state) {
          final bloc = context.read<ProductSearchBloc>();
          return AppAdminPageLayout(
            title: 'Busca de produtos',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Wrap(
                  spacing: AppSpacing.spacing12,
                  runSpacing: AppSpacing.spacing12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: AppSearchField(
                        hintText: 'Nome, SKU, referencia, EAN ou tag',
                        isSearching: state.isSearching,
                        onSearch: (query) =>
                            bloc.add(ProductSearchQueryChanged(query)),
                      ),
                    ),
                    SegmentedButton<ProductSearchSource>(
                      segments: const <ButtonSegment<ProductSearchSource>>[
                        ButtonSegment<ProductSearchSource>(
                          value: ProductSearchSource.remote,
                          icon: Icon(Icons.cloud_done_outlined),
                          label: Text('Online'),
                        ),
                        ButtonSegment<ProductSearchSource>(
                          value: ProductSearchSource.offline,
                          icon: Icon(Icons.offline_bolt_outlined),
                          label: Text('Offline'),
                        ),
                      ],
                      selected: <ProductSearchSource>{state.source},
                      onSelectionChanged: (selected) =>
                          bloc.add(ProductSearchSourceChanged(selected.single)),
                    ),
                  ],
                ),
                if (state.isShowingPotentiallyStaleOfflineData) ...<Widget>[
                  const SizedBox(height: AppSpacing.spacing12),
                  _OfflineNotice(productCount: state.products.length),
                ],
                const SizedBox(height: AppSpacing.spacing16),
                Expanded(
                  child: SingleChildScrollView(
                    child: AppProductGrid(
                      status: _gridStatus(state),
                      products: state.products
                          .map((product) => _cardDataForProduct(product, state))
                          .toList(growable: false),
                      emptyTitle: state.status == ProductSearchStatus.idle
                          ? 'Digite para buscar produtos'
                          : 'Nenhum produto encontrado',
                      emptyDescription: state.status == ProductSearchStatus.idle
                          ? 'Use nome, SKU, referencia, EAN ou tags.'
                          : 'Ajuste o termo ou troque a origem da busca.',
                      errorTitle: 'Nao foi possivel buscar produtos',
                      errorMessage:
                          state.failure?.message ?? 'Tente novamente em breve.',
                      retryLabel: 'Tentar novamente',
                      onRetry: () => bloc.add(const ProductSearchRetried()),
                      onProductTap: (card) {
                        final product = state.products.firstWhere(
                          (item) => item.id == card.id,
                        );
                        onProductSelected?.call(product);
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  AppProductGridStatus _gridStatus(ProductSearchState state) {
    return switch (state.status) {
      ProductSearchStatus.idle => AppProductGridStatus.empty,
      ProductSearchStatus.loading => AppProductGridStatus.loading,
      ProductSearchStatus.failure => AppProductGridStatus.error,
      ProductSearchStatus.empty => AppProductGridStatus.empty,
      ProductSearchStatus.success => AppProductGridStatus.idle,
    };
  }

  AppProductCardData _cardDataForProduct(
    Product product,
    ProductSearchState state,
  ) {
    final principalPhoto = product.principalPhoto;
    final imageUrl = principalPhoto?.thumbnailUrl ?? principalPhoto?.url;
    final availability = state.availabilityByProductId[product.id];
    return AppProductCardData(
      id: product.id,
      name: product.name,
      brandOrCollection: product.brand ?? product.reference,
      imageUrl: imageUrl,
      availability: _productAvailabilityFor(availability?.status),
      availabilityLabel: availability == null
          ? null
          : _availabilityLabelFor(availability),
      badgeLabels: <String>[
        product.sku.value,
        if (product.tags.isNotEmpty) product.tags.first,
      ],
    );
  }

  AppProductAvailability _productAvailabilityFor(
    VariantAvailabilityStatus? status,
  ) {
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
      VariantAvailabilityStatus.unavailable => 'Indisponivel',
    };
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice({required this.productCount});

  final int productCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.radius8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing12),
        child: Row(
          children: <Widget>[
            Icon(Icons.sync_problem_outlined, color: colors.warning),
            const SizedBox(width: AppSpacing.spacing8),
            Expanded(
              child: Text(
                productCount == 1
                    ? 'Resultado offline: pode estar desatualizado.'
                    : 'Resultados offline: podem estar desatualizados.',
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
