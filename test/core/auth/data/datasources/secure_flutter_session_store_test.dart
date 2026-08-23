import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/auth/data/datasources/secure_flutter_session_store.dart';

void main() {
  group('SecureFlutterSessionStore', () {
    late Map<String, String> backingData;
    late SecureFlutterSessionStore store;

    setUp(() {
      backingData = <String, String>{};
      FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
        backingData,
      );
      store = const SecureFlutterSessionStore(FlutterSecureStorage());
    });

    test(
      'readSignedInUserId returns null when nothing was ever persisted',
      () async {
        expect(await store.readSignedInUserId(), isNull);
      },
    );

    test('persistSignedInUserId makes the uid readable back, never as a raw '
        'password/token key', () async {
      await store.persistSignedInUserId('user-1');

      expect(await store.readSignedInUserId(), 'user-1');
      expect(backingData.keys, isNot(contains('password')));
      expect(backingData.keys, isNot(contains('token')));
    });

    test(
      'persistSignedInUserId overwrites a previously persisted uid',
      () async {
        await store.persistSignedInUserId('user-1');
        await store.persistSignedInUserId('user-2');

        expect(await store.readSignedInUserId(), 'user-2');
      },
    );

    test('clear wipes the persisted uid completely', () async {
      await store.persistSignedInUserId('user-1');

      await store.clear();

      expect(await store.readSignedInUserId(), isNull);
      expect(backingData, isEmpty);
    });

    test('clear is a no-op when nothing was ever persisted', () async {
      await store.clear();

      expect(await store.readSignedInUserId(), isNull);
    });
  });
}
