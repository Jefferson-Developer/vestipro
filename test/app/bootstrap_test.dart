import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/app/bootstrap.dart';
import 'package:vestipro/app/injection.dart';
import 'package:vestipro/core/environment/app_environment.dart';

import '../support/fake_firebase_core.dart';

/// Fake host API that always fails, simulating a broken/unavailable native
/// Firebase SDK (e.g. missing/invalid configuration on the device).
class _ThrowingFirebaseCoreHostApi implements TestFirebaseCoreHostApi {
  @override
  Future<CoreInitializeResponse> initializeApp(
    String appName,
    CoreFirebaseOptions initializeAppRequest,
  ) {
    throw PlatformException(
      code: 'unavailable',
      message: 'Firebase indisponível (simulado em teste).',
    );
  }

  @override
  Future<List<CoreInitializeResponse>> initializeCore() {
    throw PlatformException(
      code: 'unavailable',
      message: 'Firebase indisponível (simulado em teste).',
    );
  }

  @override
  Future<CoreFirebaseOptions> optionsFromResource() {
    throw UnimplementedError();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    tearDownFakeFirebaseCore();
    await resetDependencies();
  });

  testWidgets(
    'bootstrap initializes Firebase exactly once and renders VestiProApp '
    '(TASK-041: the real SessionAuthGuard sends an unauthenticated request '
    'to the login screen instead of the "about app" placeholder)',
    (tester) async {
      // Only registers the fake host API here — `bootstrap()` itself calls
      // `Firebase.initializeApp`, so this test must not call it twice
      // (unlike `setUpFakeFirebaseCore`, used by tests that render
      // `VestiProApp` directly without going through `bootstrap()`).
      final fakeApi = FakeFirebaseCoreHostApi();
      TestFirebaseCoreHostApi.setUp(fakeApi);

      await bootstrap(AppEnvironment.development);
      await tester.pumpAndSettle();

      expect(fakeApi.initializeAppCallCount, 1);
      expect(Firebase.apps, hasLength(1));
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.text('Bem-vindo de volta'), findsOneWidget);
    },
  );

  testWidgets(
    'bootstrap shows the friendly error screen instead of crashing when '
    'Firebase fails to initialize',
    (tester) async {
      TestFirebaseCoreHostApi.setUp(_ThrowingFirebaseCoreHostApi());

      await bootstrap(AppEnvironment.development);
      await tester.pumpAndSettle();

      expect(Firebase.apps, isEmpty);
      expect(find.text('Não foi possível iniciar o VestiPro'), findsOneWidget);
      expect(
        find.textContaining('FirebaseInitializationException'),
        findsOneWidget,
      );
    },
  );
}
