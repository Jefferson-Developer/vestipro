import 'dart:typed_data';

import 'package:injectable/injectable.dart';

import 'image_compressor.dart';

/// Compresses/resizes an image before it reaches
/// [FirebaseStorageDataSource.uploadFile] — kept as its own composition step
/// (not inside the storage datasource) so the datasource itself stays
/// agnostic to file type: callers that upload a non-image attachment (e.g.
/// order attachments picked through `file_picker`) never go through this
/// class.
///
/// Bytes can come from any picker (`image_picker` camera/gallery,
/// `file_picker`, a generated thumbnail, etc.) — selecting the source is a
/// feature concern (out of scope for this task); this class only prepares
/// already-obtained bytes for upload.
@lazySingleton
final class ImageUploadCompressor {
  const ImageUploadCompressor({ImageCompressor? compressor})
    : _compressor = compressor ?? const FlutterImageCompressor();

  final ImageCompressor _compressor;

  /// Default target for product photos (catalog grid + detail, EPIC-10):
  /// wide enough for a full-screen product photo on a tablet, narrow enough
  /// to keep catalog load time reasonable on mobile data.
  static const defaultMaxWidth = 1600;
  static const defaultMaxHeight = 1600;
  static const defaultQuality = 85;

  /// Images already at/under this size are not re-compressed: they were
  /// very likely already optimized upstream (e.g. a thumbnail, or a photo
  /// picked from a low-res camera setting), so re-encoding would only add
  /// CPU/latency and a second lossy JPEG pass for no real storage/bandwidth
  /// benefit. This is a deliberate design decision for this task's ambiguity
  /// ("an already-small image should not need it") rather than always
  /// running every image through the same pipeline.
  static const skipCompressionThresholdBytes = 500 * 1024;

  /// Returns [bytes] unchanged when already at/under
  /// [skipCompressionThresholdBytes]; otherwise returns the result of
  /// compressing/resizing them so neither dimension exceeds
  /// [maxWidth]/[maxHeight] at [quality].
  Future<Uint8List> compressForUpload(
    Uint8List bytes, {
    int maxWidth = defaultMaxWidth,
    int maxHeight = defaultMaxHeight,
    int quality = defaultQuality,
  }) async {
    if (bytes.lengthInBytes <= skipCompressionThresholdBytes) {
      return bytes;
    }

    return _compressor.compress(
      bytes,
      minWidth: maxWidth,
      minHeight: maxHeight,
      quality: quality,
    );
  }
}
