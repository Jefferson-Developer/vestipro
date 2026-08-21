import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vestipro/core/auth/data/datasources/firebase_auth_data_source.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/firebase_options.dart';

/// Real integration test against a locally running Firebase Auth Emulator
/// (TASK-012's "Teste de integração com o Firebase Emulator Suite").
///
/// Requires the emulator to already be running before this suite starts:
///
/// ```bash
/// firebase emulators:start --only auth --project vestipro
/// # in another terminal
/// flutter test integration_test/core/auth/firebase_auth_data_source_integration_test.dart -d chrome
/// ```
///
/// `firebase emulators:exec "flutter test integration_test/core/auth/... -d chrome"`
/// also works and tears the emulator down automatically.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const testEmail = 'task-012-integration@vestipro.test';
  const testPassword = 'Sup3rSecret!123';
  const emulatorHost = 'localhost';
  const emulatorPort = 9099;

  late FirebaseAuthDataSource dataSource;

  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await firebase.FirebaseAuth.instance.useAuthEmulator(
      emulatorHost,
      emulatorPort,
    );

    // Arrange: make sure the test account exists in the emulator, ignoring
    // "already exists" from a previous run (the emulator's state is not
    // reset between suite runs on this machine).
    try {
      await firebase.FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      );
    } on firebase.FirebaseAuthException catch (exception) {
      if (exception.code != 'email-already-in-use') rethrow;
    }
    await firebase.FirebaseAuth.instance.signOut();
  });

  setUp(() {
    dataSource = FirebaseAuthDataSource(firebase.FirebaseAuth.instance);
  });

  tearDown(() async {
    await firebase.FirebaseAuth.instance.signOut();
  });

  testWidgets('signs in with a valid e-mail and password', (tester) async {
    final user = await dataSource.signInWithEmailAndPassword(
      email: testEmail,
      password: testPassword,
    );

    expect(user.email, testEmail);
    expect(firebase.FirebaseAuth.instance.currentUser, isNotNull);
  });

  testWidgets('rejects an invalid password with an UnauthorizedException', (
    tester,
  ) async {
    await expectLater(
      dataSource.signInWithEmailAndPassword(
        email: testEmail,
        password: 'not-the-real-password',
      ),
      throwsA(isA<UnauthorizedException>()),
    );
    expect(firebase.FirebaseAuth.instance.currentUser, isNull);
  });
}
