import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/value_objects/catalog_share_outcome.dart';
import '../bloc/catalog_share_public_bloc.dart';
import '../bloc/catalog_share_public_event.dart';
import '../bloc/catalog_share_public_state.dart';

/// The public, read-only catalog share screen (TASK-081, EPIC-10) — what a
/// customer sees after opening a link a vendor sent them. Never requires
/// login, never shows price/stock/internal data, and never reveals *why* an
/// expired/revoked/unknown link stopped working beyond a clear, generic
/// message (TASK-081: "nunca erro técnico cru").
///
/// Deliberately does not reuse `ProductDetailPage`/`ProductGridPage`'s full
/// machinery (availability, size grid, add-to-order): those assume an
/// authenticated session scoped to a real `organizationId` and a live
/// product/variant store neither of which exists for an anonymous visitor
/// here — every item this page renders is the lightweight snapshot already
/// embedded in the share itself (`CatalogShareItem`), nothing is fetched
/// per-product.
class CatalogSharePublicPage extends StatelessWidget {
  const CatalogSharePublicPage({
    required this.token,
    required this.createBloc,
    super.key,
  });

  final String token;
  final CatalogSharePublicBloc Function() createBloc;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CatalogSharePublicBloc>(
      create: (_) => createBloc()..add(CatalogSharePublicStarted(token: token)),
      child: const _CatalogSharePublicView(),
    );
  }
}

class _CatalogSharePublicView extends StatelessWidget {
  const _CatalogSharePublicView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CatalogSharePublicBloc, CatalogSharePublicState>(
      builder: (context, state) {
        // TASK-179 (catálogo white-label): the organization's own branding
        // — resolved server-side, only ever populated for a valid preview
        // (see `CatalogSharePreview`'s own doc) — is applied *on top of* the
        // exact same `AppTheme` assembly the rest of the app uses
        // (`AppBrandTheme.resolveTheme`), never a second widget tree per
        // organization. A theme with no configured branding renders
        // pixel-identical to the Design System default.
        final brandTheme = AppBrandTheme.resolveTheme(
          brightness: Theme.of(context).brightness,
          primaryColorHex: state.preview?.brandingPrimaryColorHex,
        );

        return Theme(
          data: brandTheme,
          child: Scaffold(
            appBar: AppBar(title: const Text('Catálogo compartilhado')),
            body: SafeArea(
              child: switch (state.status) {
                CatalogSharePublicStatus.loading => const _LoadingView(),
                CatalogSharePublicStatus.valid => _ValidView(state: state),
                CatalogSharePublicStatus.unavailable => _UnavailableView(
                  state: state,
                ),
                CatalogSharePublicStatus.error => _ErrorView(state: state),
              },
            ),
          ),
        );
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.state});

  final CatalogSharePublicState state;

  @override
  Widget build(BuildContext context) {
    return AppErrorState(
      title: 'Não foi possível abrir este link',
      message:
          state.failure?.message ?? 'Verifique sua conexão e tente novamente.',
      retryLabel: 'Tentar novamente',
      onRetry: () => context.read<CatalogSharePublicBloc>().add(
        CatalogSharePublicStarted(token: state.token),
      ),
    );
  }
}

class _UnavailableView extends StatelessWidget {
  const _UnavailableView({required this.state});

  final CatalogSharePublicState state;

  @override
  Widget build(BuildContext context) {
    final (title, description) = _messageFor(state.unavailableReason);
    return AppEmptyState(
      icon: Icons.link_off,
      title: title,
      description: description,
    );
  }

  (String, String) _messageFor(CatalogShareOutcome? outcome) {
    return switch (outcome) {
      CatalogShareOutcome.expired => (
        'Este link expirou',
        'Peça ao vendedor um novo link de compartilhamento.',
      ),
      CatalogShareOutcome.revoked => (
        'Este link não está mais disponível',
        'O vendedor encerrou este compartilhamento. Peça um novo link.',
      ),
      CatalogShareOutcome.notFound || CatalogShareOutcome.valid || null => (
        'Link inválido',
        'Verifique se o endereço foi copiado corretamente ou peça um novo '
            'link ao vendedor.',
      ),
    };
  }
}

class _ValidView extends StatelessWidget {
  const _ValidView({required this.state});

  final CatalogSharePublicState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final preview = state.preview;
    if (preview == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (preview.brandingLogoUrl != null) ...<Widget>[
            _BrandLogo(logoUrl: preview.brandingLogoUrl!),
            const SizedBox(height: AppSpacing.spacing12),
          ],
          if (preview.organizationName != null) ...<Widget>[
            Text(
              preview.organizationName!,
              style: AppTypography.titleMedium.copyWith(
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing4),
          ],
          if (preview.collectionName != null)
            Text(
              preview.collectionName!,
              style: AppTypography.bodyMedium.copyWith(color: colors.outline),
            ),
          const SizedBox(height: AppSpacing.spacing16),
          AppProductGrid(
            products: preview.items
                .map(
                  (item) => AppProductCardData(
                    id: item.productId,
                    name: item.name,
                    imageUrl: item.imageUrl,
                  ),
                )
                .toList(growable: false),
            // No detail/order drill-down exists for an anonymous visitor —
            // see this page's own doc for why.
            onProductTap: (_) {},
          ),
        ],
      ),
    );
  }
}

/// The organization's catalog logo (TASK-179, `CatalogSharePreview
/// .brandingLogoUrl`), reserved at a fixed height so the page never shifts
/// layout while it loads. A broken/unreachable URL never shows a "broken
/// image" glyph to the visitor — it just collapses back to the same empty,
/// fixed-height box a not-yet-loaded logo already reserves, so nothing about
/// a misconfigured logo ever looks like an app bug.
class _BrandLogo extends StatelessWidget {
  const _BrandLogo({required this.logoUrl});

  final String logoUrl;

  static const double _height = 56;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: Align(
        alignment: Alignment.centerLeft,
        child: CachedNetworkImage(
          imageUrl: logoUrl,
          height: _height,
          fit: BoxFit.contain,
          placeholder: (context, url) => const SizedBox.shrink(),
          errorWidget: (context, url, error) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
