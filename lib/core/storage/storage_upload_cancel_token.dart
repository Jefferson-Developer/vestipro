import 'package:firebase_storage/firebase_storage.dart';

/// Lets a caller cancel an in-flight [FirebaseStorageDataSource.uploadFile]
/// call.
///
/// Create one per upload attempt and pass it as `cancelToken`; call [cancel]
/// (e.g. from a "cancel upload" button) to abort it. `uploadFile` attaches
/// its internal `UploadTask` to the token via [attach] — this is the only
/// place `UploadTask` is referenced outside `firebase_storage_data_source.dart`,
/// so the type still never reaches `domain/`/`presentation/`.
///
/// Retrying is deliberately the caller's responsibility: call `uploadFile`
/// again with a new token after a cancellation or failure. This datasource
/// does not retry automatically, so a caller always knows the exact failure
/// state instead of an upload silently repeating bytes/network usage.
final class StorageUploadCancelToken {
  UploadTask? _task;
  bool _canceled = false;

  bool get isCanceled => _canceled;

  void attach(UploadTask task) {
    _task = task;
  }

  Future<void> cancel() async {
    _canceled = true;
    await _task?.cancel();
  }
}
