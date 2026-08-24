import '../../../../core/errors/errors.dart';
import '../../../../core/storage/storage.dart';
import '../../domain/entities/product_media.dart';
import '../../domain/value_objects/product_media_type.dart';

enum ProductMediaSaveStatus { idle, saving, failure }

/// One photo/video upload currently in flight, tracked separately from
/// [ProductMediaState.media] (which only ever holds already-persisted
/// items) so the gallery can show progress/allow cancellation without a
/// half-uploaded item ever looking like a real, saved `ProductMedia`.
final class ProductMediaUploadInProgress {
  const ProductMediaUploadInProgress({
    required this.id,
    required this.type,
    required this.fraction,
    required this.cancelToken,
  });

  /// Same id the resulting `ProductMedia`/Storage file name will use once
  /// the upload completes.
  final String id;
  final ProductMediaType type;

  /// `0.0`–`1.0`.
  final double fraction;

  /// Lets [ProductMediaBloc] cancel this exact upload — see
  /// `ProductMediaUploadCancelled`.
  final StorageUploadCancelToken cancelToken;

  ProductMediaUploadInProgress copyWith({double? fraction}) {
    return ProductMediaUploadInProgress(
      id: id,
      type: type,
      fraction: fraction ?? this.fraction,
      cancelToken: cancelToken,
    );
  }
}

/// State for [ProductMediaBloc] (TASK-068).
final class ProductMediaState {
  const ProductMediaState({
    this.organizationId = '',
    this.productId = '',
    this.updatedBy = '',
    this.actorName = '',
    this.media = const <ProductMedia>[],
    this.uploads = const <ProductMediaUploadInProgress>[],
    this.saveStatus = ProductMediaSaveStatus.idle,
    this.failure,
    this.videoMaxDurationSeconds = 60,
    this.videoMaxSizeBytes = 50 * 1024 * 1024,
  });

  final String organizationId;
  final String productId;
  final String updatedBy;
  final String actorName;
  final List<ProductMedia> media;
  final List<ProductMediaUploadInProgress> uploads;
  final ProductMediaSaveStatus saveStatus;
  final Failure? failure;

  /// Read once from `FeatureFlagRegistry.configProductsVideoMaxDurationSeconds`
  /// when the gallery starts (TASK-068's "limite ... configurável por
  /// organização").
  final int videoMaxDurationSeconds;

  /// Read once from `FeatureFlagRegistry.configProductsVideoMaxSizeMb`
  /// (already converted to bytes).
  final int videoMaxSizeBytes;

  bool get isSaving => saveStatus == ProductMediaSaveStatus.saving;

  /// [media] restricted to photos, sorted by `order` — mirrors
  /// `Product.photos`.
  List<ProductMedia> get photos {
    final result = media
        .where((item) => item.type == ProductMediaType.photo)
        .toList();
    result.sort((a, b) => a.order.compareTo(b.order));
    return result;
  }

  /// [media] restricted to videos, sorted by `order` — mirrors
  /// `Product.videos`.
  List<ProductMedia> get videos {
    final result = media
        .where((item) => item.type == ProductMediaType.video)
        .toList();
    result.sort((a, b) => a.order.compareTo(b.order));
    return result;
  }

  ProductMediaState copyWith({
    String? organizationId,
    String? productId,
    String? updatedBy,
    String? actorName,
    List<ProductMedia>? media,
    List<ProductMediaUploadInProgress>? uploads,
    ProductMediaSaveStatus? saveStatus,
    Failure? failure,
    int? videoMaxDurationSeconds,
    int? videoMaxSizeBytes,
    bool clearFailure = false,
  }) {
    return ProductMediaState(
      organizationId: organizationId ?? this.organizationId,
      productId: productId ?? this.productId,
      updatedBy: updatedBy ?? this.updatedBy,
      actorName: actorName ?? this.actorName,
      media: media ?? this.media,
      uploads: uploads ?? this.uploads,
      saveStatus: saveStatus ?? this.saveStatus,
      failure: clearFailure ? null : failure ?? this.failure,
      videoMaxDurationSeconds:
          videoMaxDurationSeconds ?? this.videoMaxDurationSeconds,
      videoMaxSizeBytes: videoMaxSizeBytes ?? this.videoMaxSizeBytes,
    );
  }
}
