/// Upload progress snapshot exposed by [FirebaseStorageDataSource.uploadFile]
/// so callers get feedback without the SDK's `TaskSnapshot`/`UploadTask`
/// types ever leaving `lib/core/storage/`.
final class StorageUploadProgress {
  const StorageUploadProgress({
    required this.bytesTransferred,
    required this.totalBytes,
  });

  final int bytesTransferred;
  final int totalBytes;

  /// `0.0`–`1.0`. `0` when [totalBytes] is not yet known (`0`), instead of
  /// dividing by zero.
  double get fraction => totalBytes == 0 ? 0 : bytesTransferred / totalBytes;
}
