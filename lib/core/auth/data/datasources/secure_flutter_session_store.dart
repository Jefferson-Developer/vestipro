import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

import 'secure_session_store.dart';

/// [SecureSessionStore] backed by `flutter_secure_storage` (Keychain on
/// iOS/macOS, Keystore-backed EncryptedSharedPreferences on Android, DPAPI
/// on Windows) — never `SharedPreferences`, which is not encrypted at rest.
@LazySingleton(as: SecureSessionStore)
final class SecureFlutterSessionStore implements SecureSessionStore {
  const SecureFlutterSessionStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _signedInUserIdKey = 'vestipro.session.signed_in_user_id';

  @override
  Future<void> persistSignedInUserId(String uid) {
    return _storage.write(key: _signedInUserIdKey, value: uid);
  }

  @override
  Future<String?> readSignedInUserId() {
    return _storage.read(key: _signedInUserIdKey);
  }

  @override
  Future<void> clear() {
    return _storage.delete(key: _signedInUserIdKey);
  }
}
