import 'dart:typed_data';

import 'storage_upload_cancel_token.dart';
import 'storage_upload_progress.dart';

/// Data-layer contract for the Firebase Storage SDK. Implementations
/// translate SDK-specific exceptions into [AppException]s — no
/// `firebase_storage` type may leak past this boundary (same rule as
/// `AuthDataSource` for `firebase_auth`).
///
/// Agnostic to file type/content: image compression (see
/// `ImageUploadCompressor`) and file/image picking (`image_picker`,
/// `file_picker` — a future feature concern) both happen before bytes reach
/// this contract.
abstract interface class StorageDataSource {
  /// Uploads [bytes] to [path] (always built through `StoragePaths`) and
  /// returns the resulting download URL.
  ///
  /// [onProgress], when provided, is called with each upload progress
  /// snapshot. [cancelToken], when provided, lets the caller abort the
  /// upload with `cancelToken.cancel()`; a cancelled upload completes this
  /// future with an error (see `mapStorageExceptionToAppException`'s
  /// `canceled` case) — this method itself never retries automatically.
  Future<String> uploadFile({
    required String path,
    required Uint8List bytes,
    String? contentType,
    void Function(StorageUploadProgress progress)? onProgress,
    StorageUploadCancelToken? cancelToken,
  });

  Future<String> getDownloadUrl({required String path});

  Future<void> deleteFile({required String path});
}
