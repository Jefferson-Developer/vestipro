import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../products/domain/entities/product.dart';
import '../../domain/entities/catalog_campaign.dart';
import '../bloc/lookbook_bloc.dart';
import '../bloc/lookbook_event.dart';
import '../bloc/lookbook_state.dart';

/// The public lookbook/campaign screen (TASK-080, EPIC-10): editorial
/// narrative for one `CatalogCampaign` — cover + editorial images,
/// descriptive text and a carousel of related products, reusing the exact
/// same `AppProductCarousel`/`AppProductCardData` the catalog home already
/// established (TASK-076), never a bespoke card.
///
/// Layout: mobile stacks everything in one column (cover, texto, imagens
/// editoriais, carrossel); tablet/desktop split into two columns — images
/// on the left, texto + carrossel on the right — so the extra width is
/// used instead of just stretching the mobile layout, the same
/// responsiveness rule `CatalogHomePage` already follows.
///
/// A campaign outside its activation window (or that never existed) is
/// indistinguishable from "not found" — `LookbookBloc` already applies
/// `CatalogCampaign.isVisibleAt` before this widget ever sees it, so this
/// screen has no "expired" branch to accidentally get wrong.
class LookbookPage extends StatelessWidget {
  const LookbookPage({
    required this.organizationId,
    required this.campaignId,
    required this.createBloc,
    this.onProductTap,
    super.key,
  });

  final String organizationId;
  final String campaignId;
  final LookbookBloc Function() createBloc;

  /// Called when the viewer taps a related product — routing to the
  /// product detail screen is decided by whoever instantiates this page
  /// (TASK-078's `ProductDetailPage`), never by the page itself.
  final void Function(Product product)? onProductTap;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LookbookBloc>(
      create: (_) => createBloc()
        ..add(
          LookbookStarted(
            organizationId: organizationId,
            campaignId: campaignId,
          ),
        ),
      child: _LookbookView(onProductTap: onProductTap),
    );
  }
}

class _LookbookView extends StatelessWidget {
  const _LookbookView({this.onProductTap});

  final void Function(Product product)? onProductTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<LookbookBloc, LookbookState>(
          builder: (context, state) {
            switch (state.status) {
              case LookbookStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case LookbookStatus.unavailable:
                return AppEmptyState(
                  icon: Icons.auto_awesome_outlined,
                  title: 'Campanha indisponível',
                  description:
                      'Esta campanha não está mais disponível ou ainda não '
                      'foi publicada.',
                );
              case LookbookStatus.failure:
                return AppErrorState(
                  title: 'Não foi possível carregar a campanha',
                  message:
                      state.failure?.message ?? 'Tente novamente em breve.',
                  retryLabel: 'Tentar novamente',
                  onRetry: () => context.read<LookbookBloc>().add(
                    LookbookStarted(
                      organizationId: state.organizationId,
                      campaignId: state.campaignId,
                    ),
                  ),
                );
              case LookbookStatus.ready:
                return _LookbookContent(
                  campaign: state.campaign!,
                  relatedProducts: state.relatedProducts,
                  onProductTap: onProductTap,
                );
            }
          },
        ),
      ),
    );
  }
}

class _LookbookContent extends StatelessWidget {
  const _LookbookContent({
    required this.campaign,
    required this.relatedProducts,
    this.onProductTap,
  });

  final CatalogCampaign campaign;
  final List<Product> relatedProducts;
  final void Function(Product product)? onProductTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final breakpoint = AppBreakpoints.resolve(constraints.maxWidth);
        final isWide =
            breakpoint == AppBreakpoint.desktop ||
            breakpoint == AppBreakpoint.largeDesktop;

        final gallery = _LookbookGallery(campaign: campaign);
        final info = _LookbookInfo(
          campaign: campaign,
          relatedProducts: relatedProducts,
          onProductTap: onProductTap,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.spacing16),
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(flex: 3, child: gallery),
                    const SizedBox(width: AppSpacing.spacing24),
                    Expanded(flex: 2, child: info),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[gallery, info],
                ),
        );
      },
    );
  }
}

class _LookbookGallery extends StatelessWidget {
  const _LookbookGallery({required this.campaign});

  final CatalogCampaign campaign;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final images = <String>[
      if (campaign.imageUrl != null) campaign.imageUrl!,
      ...campaign.editorialImageUrls,
    ];

    if (images.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.radius16),
        child: Container(
          height: 240,
          color: colors.surfaceContainer,
          alignment: Alignment.center,
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 48,
            color: colors.outline,
          ),
        ),
      );
    }

    return Column(
      children: <Widget>[
        for (final url in images)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.spacing12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.radius16),
              child: Image.network(
                url,
                width: double.infinity,
                height: 360,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 360,
                  color: colors.surfaceContainer,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: colors.outline,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LookbookInfo extends StatelessWidget {
  const _LookbookInfo({
    required this.campaign,
    required this.relatedProducts,
    this.onProductTap,
  });

  final CatalogCampaign campaign;
  final List<Product> relatedProducts;
  final void Function(Product product)? onProductTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          campaign.title,
          style: AppTypography.headlineMedium.copyWith(color: colors.onSurface),
        ),
        if (campaign.subtitle != null) ...<Widget>[
          const SizedBox(height: AppSpacing.spacing4),
          Text(
            campaign.subtitle!,
            style: AppTypography.titleMedium.copyWith(color: colors.outline),
          ),
        ],
        if (campaign.description != null) ...<Widget>[
          const SizedBox(height: AppSpacing.spacing16),
          Text(
            campaign.description!,
            style: AppTypography.bodyMedium.copyWith(color: colors.onSurface),
          ),
        ],
        if (relatedProducts.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.spacing24),
          Text(
            'Produtos da campanha',
            style: AppTypography.titleMedium.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: AppSpacing.spacing12),
          AppProductCarousel(
            products: relatedProducts.map(_toCardData).toList(growable: false),
            onProductTap: (card) {
              final product = relatedProducts.firstWhere(
                (candidate) => candidate.id == card.id,
              );
              context.read<LookbookBloc>().add(
                LookbookRelatedProductTapped(product.id),
              );
              onProductTap?.call(product);
            },
          ),
        ],
      ],
    );
  }

  AppProductCardData _toCardData(Product product) {
    final principalPhoto = product.principalPhoto;
    final imageUrl = principalPhoto?.thumbnailUrl ?? principalPhoto?.url;
    return AppProductCardData(
      id: product.id,
      name: product.name,
      brandOrCollection: product.brand ?? product.reference,
      imageUrl: imageUrl,
    );
  }
}
