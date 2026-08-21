import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/storage/storage.dart';
import 'package:vestipro/firebase_options.dart';

/// Real integration test against a locally running Storage Emulator
/// (TASK-014's "Teste de integração com o Firebase Emulator Suite"),
/// exercising [FirebaseStorageDataSource] exactly like a future feature
/// service built on top of it would.
///
/// `storage.rules` is intentionally `allow read, write: if false` (deny all)
/// until TASK-031 implements real Storage Security Rules — this task must
/// not loosen it ahead of time (same rule already applied to
/// `firestore.rules` by TASK-013). So instead of a full upload/download
/// round trip, this suite validates what is actually true today: the
/// datasource reaches the real Storage Emulator through a real
/// tenant-scoped path (built via [StoragePaths]), and a real
/// `unauthorized`/`permission-denied` response from the SDK is mapped to
/// [ForbiddenException] end-to-end (not just for a hand-constructed
/// [FirebaseException], like `storage_exception_mapper_test.dart` covers).
///
/// Requires the emulator to already be running before this suite starts:
///
/// ```bash
/// firebase emulators:start --only storage --project vestipro
/// # in another terminal
/// flutter test integration_test/core/storage/firebase_storage_data_source_integration_test.dart -d chrome
/// ```
///
/// `firebase emulators:exec "flutter test integration_test/core/storage/... -d chrome"`
/// also works and tears the emulator down automatically.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const organizationId = 'task-014-integration-org';
  const emulatorHost = 'localhost';
  const emulatorPort = 9199;

  late FirebaseStorageDataSource dataSource;
  late String productFilePath;

  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseStorage.instance.useStorageEmulator(
      emulatorHost,
      emulatorPort,
    );
  });

  setUp(() {
    dataSource = FirebaseStorageDataSource(FirebaseStorage.instance);
    productFilePath = StoragePaths.productFile(
      organizationId: organizationId,
      productId: 'product-1',
      fileName: 'front.jpg',
    );
  });

  testWidgets(
    'uploadFile() against the real emulator maps a deny-all unauthorized '
    'response to ForbiddenException',
    (tester) async {
      await expectLater(
        dataSource.uploadFile(
          path: productFilePath,
          bytes: Uint8List.fromList([1, 2, 3, 4]),
        ),
        throwsA(isA<ForbiddenException>()),
      );
    },
  );

  testWidgets(
    'getDownloadUrl() against the real emulator maps a deny-all unauthorized '
    'response to ForbiddenException',
    (tester) async {
      await expectLater(
        dataSource.getDownloadUrl(path: productFilePath),
        throwsA(isA<ForbiddenException>()),
      );
    },
  );

  testWidgets(
    'deleteFile() against the real emulator maps a deny-all unauthorized '
    'response to ForbiddenException',
    (tester) async {
      await expectLater(
        dataSource.deleteFile(path: productFilePath),
        throwsA(isA<ForbiddenException>()),
      );
    },
  );
}
