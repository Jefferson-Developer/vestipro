import 'dart:async' show unawaited;

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:collection/collection.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/feature_flags/feature_flags.dart';
import '../../../../core/storage/storage.dart';
import '../../domain/entities/product_media.dart';
import '../../domain/product_media_rules.dart';
import '../../domain/usecases/update_product_media_use_case.dart';
import '../../domain/value_objects/product_media_type.dart';
import 'product_media_event.dart';
import 'product_media_state.dart';

/// Drives the product media gallery (TASK-068): upload with compression and
/// thumbnail generation, reordering, principal-photo selection and removal,
/// all funneled through [updateMedia] so `Product.media` is never mutated
/// from anywhere else.
///
/// Every upload event ([ProductMediaPhotoPicked]/[ProductMediaVideoPicked])
/// runs through a `sequential()` transformer scoped to its own event type —
/// two photos queue one after another, but a photo and a video upload may
/// still run concurrently, each tracked as its own
/// [ProductMediaUploadInProgress] entry so [ProductMediaUploadCancelled] can
/// target either independently.
@injectable
final class ProductMediaBloc
    extends Bloc<ProductMediaEvent, ProductMediaState> {
  ProductMediaBloc({
    required this.storage,
    required this.updateMedia,
    required this.featureFlagService,
    required this.analyticsService,
    this.compressor = const ImageUploadCompressor(),
    this.thumbnailCompressor = const FlutterImageCompressor(),
  }) : super(const ProductMediaState()) {
    on<ProductMediaStarted>(_onStarted);
    on<ProductMediaPhotoPicked>(_onPhotoPicked, transformer: sequential());
    on<ProductMediaVideoPicked>(_onVideoPicked, transformer: sequential());
    on<ProductMediaUploadCancelled>(_onUploadCancelled);
    on<ProductMediaReordered>(_onReordered, transformer: sequential());
    on<ProductMediaPrincipalSet>(_onPrincipalSet, transformer: sequential());
    on<ProductMediaRemoved>(_onRemoved, transformer: sequential());
  }

  final StorageDataSource storage;
  final ImageUploadCompressor compressor;
  final ImageCompressor thumbnailCompressor;
  final UpdateProductMediaUseCase updateMedia;
  final FeatureFlagService featureFlagService;
  final AnalyticsService analyticsService;
  final Uuid _uuid = const Uuid();

  /// A thumbnail this small is never mistaken for the full-resolution photo
  /// — same "never load the original in a grid" rule `AppProductGrid`
  /// depends on for the catalog (EPIC-10).
  static const _thumbnailMaxDimension = 400;
  static const _thumbnailQuality = 70;

  void _onStarted(ProductMediaStarted event, Emitter<ProductMediaState> emit) {
    final maxDurationSeconds = featureFlagService.getInt(
      FeatureFlagRegistry.configProductsVideoMaxDurationSeconds,
    );
    final maxSizeMb = featureFlagService.getInt(
      FeatureFlagRegistry.configProductsVideoMaxSizeMb,
    );
    emit(
      ProductMediaState(
        organizationId: event.organizationId,
        productId: event.productId,
        updatedBy: event.updatedBy,
        actorName: event.actorName,
        media: event.initialMedia,
        videoMaxDurationSeconds: maxDurationSeconds,
        videoMaxSizeBytes: maxSizeMb * 1024 * 1024,
      ),
    );
  }

  Future<void> _onPhotoPicked(
    ProductMediaPhotoPicked event,
    Emitter<ProductMediaState> emit,
  ) async {
    final mediaId = '${_uuid.v4()}.jpg';
    final thumbnailId = '${_uuid.v4()}_thumb.jpg';
    final cancelToken = StorageUploadCancelToken();
    emit(
      state.copyWith(
        uploads: <ProductMediaUploadInProgress>[
          ...state.uploads,
          ProductMediaUploadInProgress(
            id: mediaId,
            type: ProductMediaType.photo,
            fraction: 0,
            cancelToken: cancelToken,
          ),
        ],
        clearFailure: true,
      ),
    );

    try {
      final compressed = await compressor.compressForUpload(event.bytes);
      final url = await storage.uploadFile(
        path: _productFilePath(mediaId),
        bytes: compressed,
        contentType: 'image/jpeg',
        cancelToken: cancelToken,
        onProgress: (progress) => _updateUploadProgress(
          emit,
          uploadId: mediaId,
          fraction: progress.fraction,
        ),
      );

      final thumbnailBytes = await thumbnailCompressor.compress(
        event.bytes,
        minWidth: _thumbnailMaxDimension,
        minHeight: _thumbnailMaxDimension,
        quality: _thumbnailQuality,
      );
      final thumbnailUrl = await storage.uploadFile(
        path: _productFilePath(thumbnailId),
        bytes: thumbnailBytes,
        contentType: 'image/jpeg',
      );

      await _persistAppend(
        emit,
        uploadId: mediaId,
        newMedia: ProductMedia(
          id: mediaId,
          type: ProductMediaType.photo,
          url: url,
          thumbnailUrl: thumbnailUrl,
          order: 0,
          colorId: event.colorId,
        ),
      );
    } catch (exception) {
      _handleUploadException(emit, uploadId: mediaId, exception: exception);
    }
  }

  Future<void> _onVideoPicked(
    ProductMediaVideoPicked event,
    Emitter<ProductMediaState> emit,
  ) async {
    if (event.bytes.lengthInBytes > state.videoMaxSizeBytes) {
      final maxMb = state.videoMaxSizeBytes ~/ (1024 * 1024);
      emit(
        state.copyWith(
          saveStatus: ProductMediaSaveStatus.failure,
          failure: ValidationFailure(
            'O vídeo excede o limite de $maxMb MB permitido pela organização.',
            code: 'product_video_too_large',
          ),
        ),
      );
      return;
    }
    if (event.duration.inSeconds > state.videoMaxDurationSeconds) {
      emit(
        state.copyWith(
          saveStatus: ProductMediaSaveStatus.failure,
          failure: ValidationFailure(
            'O vídeo excede o limite de ${state.videoMaxDurationSeconds} '
            'segundos permitido pela organização.',
            code: 'product_video_too_long',
          ),
        ),
      );
      return;
    }

    final mediaId = '${_uuid.v4()}.${event.fileExtension}';
    final cancelToken = StorageUploadCancelToken();
    emit(
      state.copyWith(
        uploads: <ProductMediaUploadInProgress>[
          ...state.uploads,
          ProductMediaUploadInProgress(
            id: mediaId,
            type: ProductMediaType.video,
            fraction: 0,
            cancelToken: cancelToken,
          ),
        ],
        clearFailure: true,
      ),
    );

    try {
      final url = await storage.uploadFile(
        path: _productFilePath(mediaId),
        bytes: event.bytes,
        contentType: event.contentType,
        cancelToken: cancelToken,
        onProgress: (progress) => _updateUploadProgress(
          emit,
          uploadId: mediaId,
          fraction: progress.fraction,
        ),
      );

      await _persistAppend(
        emit,
        uploadId: mediaId,
        newMedia: ProductMedia(
          id: mediaId,
          type: ProductMediaType.video,
          url: url,
          order: 0,
        ),
      );
    } catch (exception) {
      _handleUploadException(emit, uploadId: mediaId, exception: exception);
    }
  }

  void _onUploadCancelled(
    ProductMediaUploadCancelled event,
    Emitter<ProductMediaState> emit,
  ) {
    for (final upload in state.uploads) {
      if (upload.id == event.uploadId) {
        unawaited(upload.cancelToken.cancel());
        return;
      }
    }
  }

  Future<void> _onReordered(
    ProductMediaReordered event,
    Emitter<ProductMediaState> emit,
  ) async {
    final reordered = reorderProductMedia(
      state.media,
      type: event.type,
      orderedIds: event.orderedIds,
    );
    await _persist(emit, reordered);
  }

  Future<void> _onPrincipalSet(
    ProductMediaPrincipalSet event,
    Emitter<ProductMediaState> emit,
  ) async {
    final updated = setPrincipalProductMedia(
      state.media,
      mediaId: event.mediaId,
    );
    await _persist(emit, updated);
  }

  Future<void> _onRemoved(
    ProductMediaRemoved event,
    Emitter<ProductMediaState> emit,
  ) async {
    final removedItem = state.media.firstWhereOrNull(
      (item) => item.id == event.mediaId,
    );
    final updated = removeProductMedia(state.media, mediaId: event.mediaId);
    final persisted = await _persist(emit, updated);
    if (persisted && removedItem != null) {
      // Best-effort: the source of truth (Product.media) is already
      // updated, so a failure deleting the underlying Storage object only
      // leaves an orphaned file behind — never a dangling reference in
      // Firestore. See this task's completion notes.
      unawaited(storage.deleteFile(path: _productFilePath(removedItem.id)));
      if (removedItem.thumbnailUrl != null) {
        final thumbnailId = _thumbnailIdFor(removedItem);
        if (thumbnailId != null) {
          unawaited(storage.deleteFile(path: _productFilePath(thumbnailId)));
        }
      }
    }
  }

  Future<void> _persistAppend(
    Emitter<ProductMediaState> emit, {
    required String uploadId,
    required ProductMedia newMedia,
  }) async {
    final updated = appendProductMedia(state.media, newMedia);
    await _persist(emit, updated, uploadIdToClear: uploadId);
    await analyticsService.logEvent(
      AnalyticsEvents.productMediaUpdated,
      parameters: <String, Object?>{
        'organization_id': state.organizationId,
        'product_id': state.productId,
        'media_type': newMedia.type.name,
        'media_count': state.media.length,
      },
    );
  }

  /// Persists [media] via [updateMedia], clearing [uploadIdToClear] from
  /// `state.uploads` on success either way (an upload id is only ever
  /// passed by [_persistAppend], after its own upload already finished).
  /// Returns whether the persist actually succeeded.
  Future<bool> _persist(
    Emitter<ProductMediaState> emit,
    List<ProductMedia> media, {
    String? uploadIdToClear,
  }) async {
    emit(
      state.copyWith(
        saveStatus: ProductMediaSaveStatus.saving,
        clearFailure: true,
      ),
    );

    final result = await updateMedia(
      organizationId: state.organizationId,
      id: state.productId,
      media: media,
      updatedBy: state.updatedBy,
      actorName: state.actorName,
    );
    if (emit.isDone) return false;

    return result.fold(
      onSuccess: (product) {
        emit(
          state.copyWith(
            media: product.media,
            saveStatus: ProductMediaSaveStatus.idle,
            uploads: uploadIdToClear == null
                ? state.uploads
                : state.uploads
                      .where((upload) => upload.id != uploadIdToClear)
                      .toList(growable: false),
            clearFailure: true,
          ),
        );
        return true;
      },
      onFailure: (failure) {
        emit(
          state.copyWith(
            saveStatus: ProductMediaSaveStatus.failure,
            failure: failure,
            uploads: uploadIdToClear == null
                ? state.uploads
                : state.uploads
                      .where((upload) => upload.id != uploadIdToClear)
                      .toList(growable: false),
          ),
        );
        return false;
      },
    );
  }

  void _updateUploadProgress(
    Emitter<ProductMediaState> emit, {
    required String uploadId,
    required double fraction,
  }) {
    if (emit.isDone) return;
    emit(
      state.copyWith(
        uploads: state.uploads
            .map(
              (upload) => upload.id == uploadId
                  ? upload.copyWith(fraction: fraction)
                  : upload,
            )
            .toList(growable: false),
      ),
    );
  }

  void _handleUploadException(
    Emitter<ProductMediaState> emit, {
    required String uploadId,
    required Object exception,
  }) {
    if (emit.isDone) return;
    final remainingUploads = state.uploads
        .where((upload) => upload.id != uploadId)
        .toList(growable: false);

    // A caller-initiated cancellation is not a failure to surface — the
    // user already knows they asked for this outcome (see
    // `mapStorageExceptionToAppException`'s `canceled` case).
    if (exception is ConflictException && exception.code == 'canceled') {
      emit(state.copyWith(uploads: remainingUploads));
      return;
    }

    emit(
      state.copyWith(
        uploads: remainingUploads,
        saveStatus: ProductMediaSaveStatus.failure,
        failure: exception is AppException
            ? mapAppExceptionToFailure(exception)
            : UnexpectedFailure(
                'Não foi possível enviar o arquivo.',
                code: 'product_media_upload_unexpected',
                cause: exception,
              ),
      ),
    );
  }

  String _productFilePath(String fileName) {
    return StoragePaths.productFile(
      organizationId: state.organizationId,
      productId: state.productId,
      fileName: fileName,
    );
  }

  /// The thumbnail's own Storage file name cannot be derived from
  /// [ProductMedia.id] alone (it is a sibling upload, not a suffix of it) —
  /// it can only be recovered from its download URL, which already encodes
  /// the exact Storage path `getDownloadURL()` returned it for.
  String? _thumbnailIdFor(ProductMedia media) {
    final url = media.thumbnailUrl;
    if (url == null) return null;
    final uri = Uri.tryParse(url);
    final encodedPath = uri?.pathSegments.lastOrNull;
    if (encodedPath == null) return null;
    final decoded = Uri.decodeComponent(encodedPath);
    return decoded.split('/').last;
  }
}
