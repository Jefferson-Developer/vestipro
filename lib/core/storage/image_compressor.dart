import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Thin, mockable wrapper around the `flutter_image_compress` static API.
///
/// `FlutterImageCompress.compressWithList` cannot be mocked directly (it is
/// a static method), so [ImageUploadCompressor] depends on this interface
/// instead of calling the plugin directly — this is what lets
/// `image_upload_compressor_test.dart` verify compression decisions with a
/// fake, without touching platform channels.
abstract interface class ImageCompressor {
  /// Re-encodes [bytes] as JPEG, scaled down so that neither dimension goes
  /// below [minWidth]/[minHeight] (the `flutter_image_compress` "floor",
  /// not a target size — an image already smaller than the floor is
  /// re-encoded at [quality] but not upscaled).
  Future<Uint8List> compress(
    Uint8List bytes, {
    required int minWidth,
    required int minHeight,
    required int quality,
  });
}

final class FlutterImageCompressor implements ImageCompressor {
  const FlutterImageCompressor();

  @override
  Future<Uint8List> compress(
    Uint8List bytes, {
    required int minWidth,
    required int minHeight,
    required int quality,
  }) {
    return FlutterImageCompress.compressWithList(
      bytes,
      minWidth: minWidth,
      minHeight: minHeight,
      quality: quality,
    );
  }
}
