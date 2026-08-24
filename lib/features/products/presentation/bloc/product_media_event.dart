import 'dart:typed_data';

import '../../domain/entities/product_media.dart';
import '../../domain/value_objects/product_media_type.dart';

/// Events for [ProductMediaBloc] (TASK-068).
///
/// Picking the actual file (`image_picker`/`file_picker`, camera vs.
/// gallery, ...) is deliberately a widget-level concern, exactly like
/// `ImageUploadCompressor`'s own docs already establish — every event here
/// only ever carries already-read bytes, so the bloc stays fully testable
/// without platform channels.
sealed class ProductMediaEvent {
  const ProductMediaEvent();
}

/// Loads the gallery for one already-saved Product. Never dispatched for a
/// brand-new, not-yet-persisted product — `ProductMediaGallerySection`
/// (the widget) only creates this bloc once `ProductFormState.currentProduct`
/// exists, since every Storage path requires a real `productId`.
final class ProductMediaStarted extends ProductMediaEvent {
  const ProductMediaStarted({
    required this.organizationId,
    required this.productId,
    required this.updatedBy,
    required this.actorName,
    required this.initialMedia,
  });

  final String organizationId;
  final String productId;
  final String updatedBy;
  final String actorName;
  final List<ProductMedia> initialMedia;
}

/// A photo was picked and read into [bytes]. Always re-encoded to JPEG by
/// [ImageUploadCompressor]/`FlutterImageCompressor`, regardless of the
/// original format, so the bloc never needs to inspect/forward a content
/// type for this event.
final class ProductMediaPhotoPicked extends ProductMediaEvent {
  const ProductMediaPhotoPicked({required this.bytes, this.colorId});

  final Uint8List bytes;

  /// Scopes this photo to one specific `ProductColor` (TASK-070, not yet
  /// implemented) instead of the whole product.
  final String? colorId;
}

/// A short video was picked and read into [bytes]. Never compressed —
/// re-encoding video client-side is out of this task's scope — so
/// [contentType]/[fileExtension] are forwarded as-is from whatever the
/// picker reported, and [duration] is what the client-side length limit
/// (`FeatureFlagRegistry.configProductsVideoMaxDurationSeconds`) is checked
/// against before any byte is uploaded.
final class ProductMediaVideoPicked extends ProductMediaEvent {
  const ProductMediaVideoPicked({
    required this.bytes,
    required this.contentType,
    required this.fileExtension,
    required this.duration,
  });

  final Uint8List bytes;
  final String contentType;
  final String fileExtension;
  final Duration duration;
}

/// Cancels the in-flight upload identified by [uploadId] (one of
/// [ProductMediaState.uploads]).
final class ProductMediaUploadCancelled extends ProductMediaEvent {
  const ProductMediaUploadCancelled(this.uploadId);

  final String uploadId;
}

/// Persists a new display order for every [type] media, matching a
/// drag-and-drop (Web) or "mover para cima/baixo" (mobile) interaction —
/// same "caller hands back its own already-reordered id list" contract
/// `CategoryListReorderRequested` uses for category siblings.
final class ProductMediaReordered extends ProductMediaEvent {
  const ProductMediaReordered({required this.type, required this.orderedIds});

  final ProductMediaType type;
  final List<String> orderedIds;
}

/// Marks the photo [mediaId] as the product's principal/cover photo.
final class ProductMediaPrincipalSet extends ProductMediaEvent {
  const ProductMediaPrincipalSet(this.mediaId);

  final String mediaId;
}

/// Removes the media [mediaId] — see `removeProductMedia` for the
/// auto-promotion rule this triggers when [mediaId] was the principal photo.
final class ProductMediaRemoved extends ProductMediaEvent {
  const ProductMediaRemoved(this.mediaId);

  final String mediaId;
}
