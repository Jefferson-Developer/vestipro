import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../products/domain/entities/product_media.dart';

/// Zoomable photo gallery for the product detail screen (TASK-078),
/// synchronized with the selected color: the caller (`ProductDetailPage`)
/// passes a fresh [photos] list whenever the color changes —
/// [ProductDetailGallery] resets to the first photo and never owns which
/// color is selected itself.
///
/// Uses `photo_view`'s [PhotoViewGallery] so each photo supports
/// pinch-to-zoom and drag, plus a "1/N" position indicator overlay. A
/// product with no photos for the resolved gallery (TASK-078's "produto sem
/// imagem" rule) renders an explicit placeholder instead of a blank area.
class ProductDetailGallery extends StatefulWidget {
  const ProductDetailGallery({
    required this.photos,
    this.height = 360,
    super.key,
  });

  final List<ProductMedia> photos;
  final double height;

  @override
  State<ProductDetailGallery> createState() => _ProductDetailGalleryState();
}

class _ProductDetailGalleryState extends State<ProductDetailGallery> {
  late final PageController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void didUpdateWidget(covariant ProductDetailGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_photoIdsOf(oldWidget.photos) != _photoIdsOf(widget.photos)) {
      _currentIndex = 0;
      if (_controller.hasClients) {
        _controller.jumpToPage(0);
      }
    }
  }

  String _photoIdsOf(List<ProductMedia> photos) =>
      photos.map((photo) => photo.id).join('|');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (widget.photos.isEmpty) {
      return _buildEmpty(colors);
    }

    return Semantics(
      label: 'Galeria de fotos do produto',
      container: true,
      child: SizedBox(
        height: widget.height,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: <Widget>[
            PhotoViewGallery.builder(
              key: ValueKey<String>(_photoIdsOf(widget.photos)),
              pageController: _controller,
              itemCount: widget.photos.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              backgroundDecoration: BoxDecoration(
                color: colors.surfaceContainer,
              ),
              loadingBuilder: (context, event) =>
                  const AppSkeleton(shape: AppSkeletonShape.block),
              builder: (context, index) {
                final photo = widget.photos[index];
                return PhotoViewGalleryPageOptions(
                  imageProvider: NetworkImage(photo.url),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2.5,
                  heroAttributes: PhotoViewHeroAttributes(tag: photo.id),
                );
              },
            ),
            if (widget.photos.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.spacing12),
                child: _buildPositionIndicator(colors),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionIndicator(AppColors colors) {
    return Semantics(
      liveRegion: true,
      label: 'Foto ${_currentIndex + 1} de ${widget.photos.length}',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing12,
          vertical: AppSpacing.spacing4,
        ),
        decoration: BoxDecoration(
          color: colors.onSurface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(AppRadius.radius16),
        ),
        child: Text(
          '${_currentIndex + 1}/${widget.photos.length}',
          style: AppTypography.labelMedium.copyWith(color: colors.surface),
        ),
      ),
    );
  }

  Widget _buildEmpty(AppColors colors) {
    return SizedBox(
      height: widget.height,
      child: DecoratedBox(
        decoration: BoxDecoration(color: colors.surfaceContainer),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.image_not_supported_outlined,
                size: AppIconSizes.xl,
                color: colors.outline,
              ),
              const SizedBox(height: AppSpacing.spacing8),
              Text(
                'Sem imagem disponível',
                style: AppTypography.bodyMedium.copyWith(color: colors.outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
