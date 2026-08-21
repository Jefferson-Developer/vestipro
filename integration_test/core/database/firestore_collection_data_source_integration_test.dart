import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vestipro/core/database/database.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/firebase_options.dart';

class _NoteEntity {
  const _NoteEntity({required this.id, required this.title});

  final String id;
  final String title;
}

final _notesConverter = FirestoreConverter<_NoteEntity>(
  fromJson: (data, id) =>
      _NoteEntity(id: id, title: data['title'] as String? ?? ''),
  toJson: (value) => {'title': value.title},
);

/// Real integration test against a locally running Firestore Emulator
/// (TASK-013's "Teste de integração com o Firebase Emulator Suite"),
/// exercising a sample collection under `organizations/{organizationId}`
/// exactly like a real feature datasource built on top of
/// [FirestoreCollectionDataSource] would.
///
/// `firestore.rules` is intentionally `allow read, write: if false` (deny
/// all) until TASK-030 implements real Security Rules — this task must not
/// loosen it ahead of time. So instead of a full read/write round trip, this
/// suite validates the two things that are actually true today: the
/// datasource reaches the real Firestore Emulator through the right tenant
/// path, and a real `permission-denied` from the SDK is mapped to
/// [ForbiddenException] end-to-end (not just for a hand-constructed
/// [FirebaseException] like `firestore_exception_mapper_test.dart` covers).
///
/// Requires the emulator to already be running before this suite starts:
///
/// ```bash
/// firebase emulators:start --only firestore --project vestipro
/// # in another terminal
/// flutter test integration_test/core/database/firestore_collection_data_source_integration_test.dart -d chrome
/// ```
///
/// `firebase emulators:exec "flutter test integration_test/core/database/... -d chrome"`
/// also works and tears the emulator down automatically.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const organizationId = 'task-013-integration-org';
  const emulatorHost = 'localhost';
  const emulatorPort = 8080;

  late FirestoreCollectionDataSource<_NoteEntity> dataSource;

  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, emulatorPort);
  });

  setUp(() {
    dataSource = FirestoreCollectionDataSource<_NoteEntity>(
      firestore: FirebaseFirestore.instance,
      collectionName: 'integrationNotes',
      converter: _notesConverter,
    );
  });

  testWidgets(
    'set() against the real emulator maps a deny-all permission-denied '
    'to ForbiddenException',
    (tester) async {
      await expectLater(
        dataSource.set(
          organizationId: organizationId,
          id: 'note-1',
          value: const _NoteEntity(id: 'note-1', title: 'Primeira nota'),
        ),
        throwsA(isA<ForbiddenException>()),
      );
    },
  );

  testWidgets(
    'getById() against the real emulator maps a deny-all permission-denied '
    'to ForbiddenException',
    (tester) async {
      await expectLater(
        dataSource.getById(organizationId: organizationId, id: 'note-1'),
        throwsA(isA<ForbiddenException>()),
      );
    },
  );

  testWidgets(
    'getPage() against the real emulator maps a deny-all permission-denied '
    'to ForbiddenException',
    (tester) async {
      await expectLater(
        dataSource.getPage(organizationId: organizationId, limit: 2),
        throwsA(isA<ForbiddenException>()),
      );
    },
  );
}
