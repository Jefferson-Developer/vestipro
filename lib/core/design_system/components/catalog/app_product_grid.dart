import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../foundations/foundations.dart';
import '../../theme/theme.dart';
import '../buttons/app_icon_button.dart';
import '../feedback/app_empty_state.dart';
import '../feedback/app_error_state.dart';
import '../feedback/app_skeleton.dart';
import '../tables/app_pagination.dart';

/// The lifecycle of an [AppProductGrid], mirroring every other paginated
/// Design System list ([AppDataTable]'s `AppDataTableStatus]).
enum AppProductGridStatus {
  /// Real [AppProductGrid.products] are ready to render.
  idle,

  /// Shows [AppProductGrid.loadingItemCount] skeleton cards instead of
  /// [AppProductGrid.products].
  loading,

  /// Shows [AppEmptyState] instead of the grid.
  empty,

  /// Shows [AppErrorState] instead of the grid.
  error,
}

/// Whether a product (at the color/variant level the caller has already
/// resolved for this grid card) can currently be sold.
enum AppProductAvailability {
  /// Ships from stock on hand.
  readyStock,

  /// Only available from a future stock arrival.
  futureStock,

  /// Cannot be sold right now.
  unavailable,
}

/// A single product card's data for [AppProductGrid].
///
/// Every value here is already decided by the domain/BLoC layer —
/// [AppProductGrid] never fetches an image, computes a price/discount or
/// decides availability itself, it only renders what it is given. When
/// [priceLabel] is `null`, no price is shown at all (never a fabricated
/// placeholder); when [previousPriceLabel] is also provided, it renders as
/// a "de/por" strikethrough pair.
@immutable
class AppProductCardData {
  const AppProductCardData({
    required this.id,
    required this.name,
    this.brandOrCollection,
    this.imageUrl,
    this.availableColorSwatches = const <Color>[],
    this.priceLabel,
    this.previousPriceLabel,
    this.availability = AppProductAvailability.readyStock,
    this.availabilityLabel,
    this.badgeLabels = const <String>[],
    this.isFavorite = false,
    this.onFavoriteTap,
  });

  final Object id;
  final String name;
  final String? brandOrCollection;

  /// `null` (no photo yet) is rendered with an explicit fallback icon —
  /// never a blank space that could be mistaken for a loading glitch.
  final String? imageUrl;

  /// Up to a handful of the product's available colors, rendered as small
  /// dots. Purely a "this product comes in N colors" hint — never the only
  /// place a color is named (that is [AppColorSwatchSelector]'s job on the
  /// detail screen).
  final List<Color> availableColorSwatches;

  /// The already-formatted current price (e.g. "R\$ 189,90"). `null` hides
  /// the price row entirely.
  final String? priceLabel;

  /// The already-formatted previous/list price, shown struck through next
  /// to [priceLabel] when both are provided by the domain layer with a
  /// confirmed origin (this widget never invents a "de/por" pair).
  final String? previousPriceLabel;

  final AppProductAvailability availability;
  final String? availabilityLabel;

  /// At most 2 short tags (e.g. "Lançamento", "Oferta"). Any further labels
  /// passed in are silently ignored by [AppProductGrid] — never queued or
  /// rotated — to avoid a false sense of urgency/clutter.
  final List<String> badgeLabels;

  /// Whether this product is currently favorited by the viewer (TASK-079).
  /// Only meaningful together with [onFavoriteTap] — see its doc.
  final bool isFavorite;

  /// Shows a favorite (heart) button over the card's photo when non-`null`,
  /// tapping it calls this instead of [AppProductGrid.onProductTap]. `null`
  /// (the default) hides the button entirely, so every existing caller that
  /// does not wire favorites (e.g. `AppProductCarousel`, the catalog home)
  /// renders exactly as before.
  final VoidCallback? onFavoriteTap;
}

/// The product grid every catalog/order/pick-list screen reuses.
///
/// Every card reserves a fixed 3:4 image area — via [AspectRatio] — before
/// the real photo loads, so the grid never shifts layout once images
/// arrive; a [CachedNetworkImage] placeholder/error fallback keeps that
/// same footprint for a missing/failed photo. [status] drives
/// loading/empty/error exactly like [AppDataTable], and [hasMore]/
/// [onLoadMore] wire into the same [AppPagination] "carregar mais" control
/// used everywhere else — this widget never loads the full catalog into
/// memory itself.
///
/// The column count adapts to [AppBreakpoint] (2 on mobile, 3 on tablet, 4
/// on desktop, 5 on large desktop) unless [crossAxisCount] overrides it.
///
/// ```dart
/// AppProductGrid(
///   status: state.status,
///   products: state.products,
///   hasMore: state.hasMore,
///   isLoadingMore: state.isLoadingNextPage,
///   onLoadMore: () => bloc.add(LoadNextPage()),
///   onProductTap: (product) => context.push('/catalog/${product.id}'),
/// )
/// ```
class AppProductGrid extends StatelessWidget {
  const AppProductGrid({
    super.key,
    required this.products,
    required this.onProductTap,
    this.status = AppProductGridStatus.idle,
    this.loadingItemCount = 6,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.onLoadMore,
    this.crossAxisCount,
    this.emptyTitle = 'Nenhum produto encontrado',
    this.emptyDescription,
    this.errorTitle = 'Não foi possível carregar o catálogo',
    this.errorMessage,
    this.retryLabel,
    this.onRetry,
    this.readyStockLabel = 'Pronta entrega',
    this.futureStockLabel = 'Estoque futuro',
    this.unavailableLabel = 'Indisponível',
  });

  final List<AppProductCardData> products;
  final ValueChanged<AppProductCardData> onProductTap;
  final AppProductGridStatus status;
  final int loadingItemCount;

  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;

  /// Overrides the breakpoint-resolved column count.
  final int? crossAxisCount;

  final String emptyTitle;
  final String? emptyDescription;
  final String errorTitle;
  final String? errorMessage;
  final String? retryLabel;
  final VoidCallback? onRetry;

  final String readyStockLabel;
  final String futureStockLabel;
  final String unavailableLabel;

  int _resolveCrossAxisCount(AppBreakpoint breakpoint) {
    if (crossAxisCount != null) {
      return crossAxisCount!;
    }
    return switch (breakpoint) {
      AppBreakpoint.mobile => 2,
      AppBreakpoint.tablet => 3,
      AppBreakpoint.desktop => 4,
      AppBreakpoint.largeDesktop => 5,
    };
  }

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case AppProductGridStatus.error:
        return AppErrorState(
          title: errorTitle,
          message: errorMessage ?? '',
          retryLabel: onRetry != null
              ? (retryLabel ?? 'Tentar novamente')
              : null,
          onRetry: onRetry,
        );
      case AppProductGridStatus.empty:
        return AppEmptyState(title: emptyTitle, description: emptyDescription);
      case AppProductGridStatus.loading:
      case AppProductGridStatus.idle:
        break;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final breakpoint = AppBreakpoints.resolve(constraints.maxWidth);
        final columns = _resolveCrossAxisCount(breakpoint);
        final itemCount = status == AppProductGridStatus.loading
            ? loadingItemCount
            : products.length;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: itemCount,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: AppSpacing.spacing16,
                crossAxisSpacing: AppSpacing.spacing16,
                childAspectRatio: 0.46,
              ),
              itemBuilder: (context, index) {
                if (status == AppProductGridStatus.loading) {
                  return const AppProductCardSkeleton();
                }
                final product = products[index];
                return AppProductCard(
                  product: product,
                  onTap: () => onProductTap(product),
                  readyStockLabel: readyStockLabel,
                  futureStockLabel: futureStockLabel,
                  unavailableLabel: unavailableLabel,
                );
              },
            ),
            if (status == AppProductGridStatus.idle &&
                (hasMore || isLoadingMore))
              AppPagination(
                hasMore: hasMore,
                isLoadingMore: isLoadingMore,
                onLoadMore: onLoadMore,
              ),
          ],
        );
      },
    );
  }
}

class AppProductCardSkeleton extends StatelessWidget {
  const AppProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AspectRatio(
          aspectRatio: 3 / 4,
          child: AppSkeleton(
            shape: AppSkeletonShape.card,
            radius: AppRadius.radius12,
          ),
        ),
        const SizedBox(height: AppSpacing.spacing8),
        const AppSkeleton.line(),
        const SizedBox(height: AppSpacing.spacing4),
        const AppSkeleton.line(width: AppSpacing.spacing64),
      ],
    );
  }
}

class AppProductCard extends StatelessWidget {
  const AppProductCard({
    required this.product,
    required this.onTap,
    required this.readyStockLabel,
    required this.futureStockLabel,
    required this.unavailableLabel,
    super.key,
  });

  final AppProductCardData product;
  final VoidCallback onTap;
  final String readyStockLabel;
  final String futureStockLabel;
  final String unavailableLabel;

  String get _availabilityLabel => switch (product.availability) {
    AppProductAvailability.readyStock =>
      product.availabilityLabel ?? readyStockLabel,
    AppProductAvailability.futureStock =>
      product.availabilityLabel ?? futureStockLabel,
    AppProductAvailability.unavailable =>
      product.availabilityLabel ?? unavailableLabel,
  };

  IconData get _availabilityIcon => switch (product.availability) {
    AppProductAvailability.readyStock => Icons.check_circle_outline,
    AppProductAvailability.futureStock => Icons.schedule,
    AppProductAvailability.unavailable => Icons.block,
  };

  Color _availabilityColor(AppColors colors) => switch (product.availability) {
    AppProductAvailability.readyStock => colors.success,
    AppProductAvailability.futureStock => colors.warning,
    AppProductAvailability.unavailable => colors.outline,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final visibleBadges = product.badgeLabels.take(2).toList(growable: false);

    return Semantics(
      label:
          '${product.name}${product.priceLabel != null ? ', ${product.priceLabel}' : ''}, $_availabilityLabel',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.radius12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Stack(
              children: <Widget>[
                AspectRatio(
                  aspectRatio: 3 / 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.radius12),
                    child: _buildImage(colors),
                  ),
                ),
                if (visibleBadges.isNotEmpty)
                  Positioned(
                    top: AppSpacing.spacing8,
                    left: AppSpacing.spacing8,
                    child: Wrap(
                      spacing: AppSpacing.spacing4,
                      children: visibleBadges
                          .map((label) => _buildBadge(context, label))
                          .toList(growable: false),
                    ),
                  ),
                if (product.onFavoriteTap != null)
                  Positioned(
                    top: AppSpacing.spacing4,
                    right: AppSpacing.spacing4,
                    child: _buildFavoriteButton(colors),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.spacing8),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMedium.copyWith(color: colors.onSurface),
            ),
            if (product.brandOrCollection != null)
              Text(
                product.brandOrCollection!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(color: colors.outline),
              ),
            if (product.availableColorSwatches.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.spacing4),
              _buildColorDots(colors),
            ],
            if (product.priceLabel != null) ...<Widget>[
              const SizedBox(height: AppSpacing.spacing4),
              _buildPriceRow(colors),
            ],
            const SizedBox(height: AppSpacing.spacing4),
            _buildAvailabilityRow(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(AppColors colors) {
    final imageUrl = product.imageUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildImageFallback(colors);
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) =>
          const AppSkeleton(shape: AppSkeletonShape.block),
      errorWidget: (context, url, error) => _buildImageFallback(colors),
    );
  }

  Widget _buildImageFallback(AppColors colors) {
    return Container(
      color: colors.surfaceContainer,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        size: AppIconSizes.xl,
        color: colors.outline,
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String label) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing8,
        vertical: AppSpacing.spacing4,
      ),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(AppRadius.radius4),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(color: colors.onPrimary),
      ),
    );
  }

  /// A translucent circular backdrop (for contrast over any photo) around a
  /// reused [AppIconButton] — never a bespoke icon widget — so the favorite
  /// button gets the same debounce/loading/disabled/accessibility behavior
  /// every other icon action in the app already has.
  Widget _buildFavoriteButton(AppColors colors) {
    return Material(
      color: colors.surface.withValues(alpha: 0.85),
      shape: const CircleBorder(),
      child: AppIconButton(
        icon: product.isFavorite ? Icons.favorite : Icons.favorite_border,
        semanticLabel: product.isFavorite
            ? 'Remover dos favoritos'
            : 'Adicionar aos favoritos',
        onPressed: product.onFavoriteTap,
      ),
    );
  }

  Widget _buildColorDots(AppColors colors) {
    const maxVisible = 5;
    final visible = product.availableColorSwatches
        .take(maxVisible)
        .toList(growable: false);
    final remaining = product.availableColorSwatches.length - visible.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final color in visible)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.spacing4),
            child: Container(
              width: AppSpacing.spacing12,
              height: AppSpacing.spacing12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: colors.outline),
              ),
            ),
          ),
        if (remaining > 0)
          Text(
            '+$remaining',
            style: AppTypography.labelSmall.copyWith(color: colors.outline),
          ),
      ],
    );
  }

  Widget _buildPriceRow(AppColors colors) {
    return Row(
      children: <Widget>[
        if (product.previousPriceLabel != null) ...<Widget>[
          Flexible(
            child: Text(
              product.previousPriceLabel!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color: colors.outline,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.spacing4),
        ],
        Flexible(
          child: Text(
            product.priceLabel!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelLarge.copyWith(color: colors.onSurface),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilityRow(AppColors colors) {
    final color = _availabilityColor(colors);
    return Row(
      children: <Widget>[
        Icon(_availabilityIcon, size: AppIconSizes.sm, color: color),
        const SizedBox(width: AppSpacing.spacing4),
        Flexible(
          child: Text(
            _availabilityLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
