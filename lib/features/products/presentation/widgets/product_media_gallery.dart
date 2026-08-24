import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/product_media.dart';
import '../../domain/value_objects/product_media_type.dart';
import '../bloc/product_media_bloc.dart';
import '../bloc/product_media_event.dart';
import '../bloc/product_media_state.dart';

/// The "Mídia" section of `ProductFormPage` (TASK-068): upload, reorder,
/// principal-photo selection and removal for a product's photos/short
/// video, all driven by an already-provided [ProductMediaBloc] — this
/// widget never touches `StorageDataSource`/`ProductRepository` itself.
///
/// Only ever mounted once `ProductFormState.currentProduct` exists: every
/// Storage path needs a real, already-persisted `productId`
/// (`StoragePaths.productFile`), so a brand-new draft shows a placeholder
/// asking the seller to save the product first instead of this section.
class ProductMediaGallerySection extends StatelessWidget {
  const ProductMediaGallerySection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductMediaBloc, ProductMediaState>(
      listenWhen: (previous, current) => previous.failure != current.failure,
      listener: (context, state) {
        if (state.failure != null) {
          AppSnackbar.show(
            context,
            message: state.failure!.message,
            variant: AppSnackbarVariant.error,
          );
        }
      },
      builder: (context, state) {
        final photoUploads = state.uploads
            .where((upload) => upload.type == ProductMediaType.photo)
            .toList(growable: false);
        final videoUploads = state.uploads
            .where((upload) => upload.type == ProductMediaType.video)
            .toList(growable: false);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Fotos',
              style: AppTypography.titleMedium.copyWith(
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing8),
            _MediaList(type: ProductMediaType.photo, items: state.photos),
            for (final upload in photoUploads)
              _UploadProgressRow(upload: upload),
            const SizedBox(height: AppSpacing.spacing8),
            AppButton(
              label: 'Adicionar foto',
              leadingIcon: Icons.add_photo_alternate_outlined,
              variant: AppButtonVariant.secondary,
              isDisabled: state.isSaving,
              onPressed: () => _pickPhoto(context),
            ),
            const SizedBox(height: AppSpacing.spacing24),
            Text(
              'Vídeo',
              style: AppTypography.titleMedium.copyWith(
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing8),
            _MediaList(type: ProductMediaType.video, items: state.videos),
            for (final upload in videoUploads)
              _UploadProgressRow(upload: upload),
            if (state.videos.isEmpty && videoUploads.isEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.spacing8),
              AppButton(
                label: 'Adicionar vídeo',
                leadingIcon: Icons.videocam_outlined,
                variant: AppButtonVariant.secondary,
                isDisabled: state.isSaving,
                onPressed: () => _pickVideo(context),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _pickPhoto(BuildContext context) async {
    final bloc = context.read<ProductMediaBloc>();
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    bloc.add(ProductMediaPhotoPicked(bytes: bytes));
  }

  Future<void> _pickVideo(BuildContext context) async {
    final bloc = context.read<ProductMediaBloc>();
    final file = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    final duration = await _probeVideoDuration(file);
    final extension = file.name.contains('.')
        ? file.name.split('.').last
        : 'mp4';
    bloc.add(
      ProductMediaVideoPicked(
        bytes: bytes,
        contentType: file.mimeType ?? 'video/mp4',
        fileExtension: extension,
        duration: duration,
      ),
    );
  }

  /// Reads the picked video's real duration before it is ever uploaded, so
  /// `ProductMediaBloc` can reject it against
  /// `FeatureFlagRegistry.configProductsVideoMaxDurationSeconds` without
  /// transferring a single byte first (TASK-068's "upload fora do limite é
  /// rejeitado ... antes de transferir o arquivo inteiro").
  Future<Duration> _probeVideoDuration(XFile file) async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(file.path));
    try {
      await controller.initialize();
      return controller.value.duration;
    } finally {
      await controller.dispose();
    }
  }
}

class _UploadProgressRow extends StatelessWidget {
  const _UploadProgressRow({required this.upload});

  final ProductMediaUploadInProgress upload;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  upload.type == ProductMediaType.photo
                      ? 'Enviando foto...'
                      : 'Enviando vídeo...',
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.outline,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing4),
                LinearProgressIndicator(value: upload.fraction),
              ],
            ),
          ),
          AppIconButton(
            icon: Icons.close,
            semanticLabel: 'Cancelar envio',
            variant: AppButtonVariant.text,
            onPressed: () => context.read<ProductMediaBloc>().add(
              ProductMediaUploadCancelled(upload.id),
            ),
          ),
        ],
      ),
    );
  }
}

/// One media type's ([type]) reorderable list — drag-and-drop on
/// tablet/desktop, explicit "mover para cima/baixo" on mobile, exactly like
/// `CategoriesPage._CategorySiblingList` (TASK-067) already established for
/// sibling categories.
class _MediaList extends StatelessWidget {
  const _MediaList({required this.type, required this.items});

  final ProductMediaType type;
  final List<ProductMedia> items;

  void _reorder(BuildContext context, int oldIndex, int newIndex) {
    final reordered = List<ProductMedia>.of(items);
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    context.read<ProductMediaBloc>().add(
      ProductMediaReordered(
        type: type,
        orderedIds: reordered.map((item) => item.id).toList(growable: false),
      ),
    );
  }

  void _moveBy(BuildContext context, int index, int offset) {
    final targetIndex = index + offset;
    if (targetIndex < 0 || targetIndex >= items.length) return;
    _reorder(context, index, targetIndex);
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(
        type == ProductMediaType.photo
            ? 'Nenhuma foto adicionada ainda.'
            : 'Nenhum vídeo adicionado ainda.',
        style: AppTypography.bodySmall.copyWith(color: context.colors.outline),
      );
    }

    return AppResponsiveBuilder(
      builder: (context, breakpoint) {
        final canDrag = breakpoint != AppBreakpoint.mobile;
        if (canDrag) {
          return ReorderableListView.builder(
            key: ValueKey('product-media-reorderable-${type.name}'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            onReorderItem: (oldIndex, newIndex) =>
                _reorder(context, oldIndex, newIndex),
            itemBuilder: (context, index) => _MediaTile(
              key: ValueKey(items[index].id),
              media: items[index],
              canDrag: true,
              onMoveUp: null,
              onMoveDown: null,
            ),
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (var index = 0; index < items.length; index++)
              _MediaTile(
                key: ValueKey(items[index].id),
                media: items[index],
                canDrag: false,
                onMoveUp: index == 0 ? null : () => _moveBy(context, index, -1),
                onMoveDown: index == items.length - 1
                    ? null
                    : () => _moveBy(context, index, 1),
              ),
          ],
        );
      },
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({
    required super.key,
    required this.media,
    required this.canDrag,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final ProductMedia media;
  final bool canDrag;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isPhoto = media.type == ProductMediaType.photo;

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: AppSpacing.spacing8),
      padding: const EdgeInsets.all(AppSpacing.spacing8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.radius12),
        border: Border.all(color: colors.outline.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (canDrag)
                const Padding(
                  padding: EdgeInsets.only(right: AppSpacing.spacing8),
                  child: Icon(Icons.drag_indicator, semanticLabel: 'Arrastar'),
                ),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.radius8),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: isPhoto
                      ? Image.network(
                          media.thumbnailUrl ?? media.url,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _fallbackIcon(
                                colors,
                                Icons.image_not_supported_outlined,
                              ),
                        )
                      : Container(
                          color: colors.surfaceContainer,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.play_circle_outline,
                            color: colors.outline,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.spacing12),
              if (isPhoto && media.principal)
                const AppStatusBadge(
                  label: 'Principal',
                  variant: AppStatusBadgeVariant.success,
                ),
            ],
          ),
          Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              if (isPhoto)
                AppIconButton(
                  icon: media.principal ? Icons.star : Icons.star_border,
                  semanticLabel: media.principal
                      ? 'Foto principal'
                      : 'Tornar foto principal',
                  isDisabled: media.principal,
                  onPressed: media.principal
                      ? null
                      : () => context.read<ProductMediaBloc>().add(
                          ProductMediaPrincipalSet(media.id),
                        ),
                ),
              if (!isPhoto)
                AppIconButton(
                  icon: Icons.play_arrow,
                  semanticLabel: 'Reproduzir vídeo',
                  onPressed: () => _openVideoPreview(context, media.url),
                ),
              if (!canDrag) ...<Widget>[
                AppIconButton(
                  icon: Icons.arrow_upward,
                  semanticLabel: 'Mover para cima',
                  onPressed: onMoveUp,
                ),
                AppIconButton(
                  icon: Icons.arrow_downward,
                  semanticLabel: 'Mover para baixo',
                  onPressed: onMoveDown,
                ),
              ],
              AppIconButton(
                icon: Icons.delete_outline,
                semanticLabel: isPhoto ? 'Excluir foto' : 'Excluir vídeo',
                onPressed: () => _confirmRemove(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fallbackIcon(AppColors colors, IconData icon) {
    return Container(
      color: colors.surfaceContainer,
      alignment: Alignment.center,
      child: Icon(icon, color: colors.outline),
    );
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final isPhoto = media.type == ProductMediaType.photo;
    final confirmed = await AppConfirmationDialog.show(
      context: context,
      title: isPhoto ? 'Excluir foto?' : 'Excluir vídeo?',
      message: isPhoto && media.principal
          ? 'Esta é a foto principal do produto. Ao excluí-la, outra foto '
                'será definida automaticamente como principal, se houver.'
          : 'Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
    );
    if (confirmed && context.mounted) {
      context.read<ProductMediaBloc>().add(ProductMediaRemoved(media.id));
    }
  }

  void _openVideoPreview(BuildContext context, String url) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (dialogContext) => _ProductVideoPreviewDialog(url: url),
      ),
    );
  }
}

/// A minimal in-app player with basic controls (TASK-068's "player com
/// controles básicos") — play/pause and a scrub bar, never a full custom
/// video editor.
class _ProductVideoPreviewDialog extends StatefulWidget {
  const _ProductVideoPreviewDialog({required this.url});

  final String url;

  @override
  State<_ProductVideoPreviewDialog> createState() =>
      _ProductVideoPreviewDialogState();
}

class _ProductVideoPreviewDialogState
    extends State<_ProductVideoPreviewDialog> {
  late final VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    unawaited(
      _controller.initialize().then((_) {
        if (mounted) setState(() => _initialized = true);
        unawaited(_controller.play());
      }),
    );
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (_initialized)
              AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            else
              const Padding(
                padding: EdgeInsets.all(AppSpacing.spacing32),
                child: CircularProgressIndicator(),
              ),
            if (_initialized) ...<Widget>[
              VideoProgressIndicator(_controller, allowScrubbing: true),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  AppIconButton(
                    icon: _controller.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    semanticLabel: _controller.value.isPlaying
                        ? 'Pausar'
                        : 'Reproduzir',
                    onPressed: () => setState(() {
                      unawaited(
                        _controller.value.isPlaying
                            ? _controller.pause()
                            : _controller.play(),
                      );
                    }),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
