import 'dart:async' show StreamSubscription;
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:injectable/injectable.dart';

import 'storage_data_source.dart';
import 'storage_exception_mapper.dart';
import 'storage_upload_cancel_token.dart';
import 'storage_upload_progress.dart';

@LazySingleton(as: StorageDataSource)
final class FirebaseStorageDataSource implements StorageDataSource {
  FirebaseStorageDataSource(this._storage);

  final FirebaseStorage _storage;

  @override
  Future<String> uploadFile({
    required String path,
    required Uint8List bytes,
    String? contentType,
    void Function(StorageUploadProgress progress)? onProgress,
    StorageUploadCancelToken? cancelToken,
  }) async {
    final reference = _storage.ref(path);
    final metadata = contentType == null
        ? null
        : SettableMetadata(contentType: contentType);
    final task = reference.putData(bytes, metadata);
    cancelToken?.attach(task);

    StreamSubscription<TaskSnapshot>? progressSubscription;
    if (onProgress != null) {
      progressSubscription = task.snapshotEvents.listen((snapshot) {
        onProgress(
          StorageUploadProgress(
            bytesTransferred: snapshot.bytesTransferred,
            totalBytes: snapshot.totalBytes,
          ),
        );
      });
    }

    try {
      final snapshot = await task;
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (exception, stackTrace) {
      throw mapStorageExceptionToAppException(exception, stackTrace);
    } finally {
      await progressSubscription?.cancel();
    }
  }

  @override
  Future<String> getDownloadUrl({required String path}) async {
    try {
      return await _storage.ref(path).getDownloadURL();
    } on FirebaseException catch (exception, stackTrace) {
      throw mapStorageExceptionToAppException(exception, stackTrace);
    }
  }

  @override
  Future<void> deleteFile({required String path}) async {
    try {
      await _storage.ref(path).delete();
    } on FirebaseException catch (exception, stackTrace) {
      throw mapStorageExceptionToAppException(exception, stackTrace);
    }
  }
}
