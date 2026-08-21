import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/app/bootstrap.dart';
import 'package:vestipro/app/injection.dart';
import 'package:vestipro/core/environment/app_environment.dart';

/// Fake host API that mimics a real Firebase Core plugin: it answers with no
/// pre-existing native app (`initializeCore` returns an empty list, just
/// like a Flutter app with no `google-services.json`/`GoogleService-Info.plist`
/// bundled) and hands back whatever options `bootstrap` requests.
class _FakeFirebaseCoreHostApi implements TestFirebaseCoreHostApi {
  int initializeAppCallCount = 0;

  @override
  Future<CoreInitializeResponse> initializeApp(
    String appName,
    CoreFirebaseOptions initializeAppRequest,
  ) async {
    initializeAppCallCount++;
    return CoreInitializeResponse(
      name: appName,
      options: initializeAppRequest,
      pluginConstants: const <String?, Object?>{},
    );
  }

  @override
  Future<List<CoreInitializeResponse>> initializeCore() async {
    return <CoreInitializeResponse>[];
  }

  @override
  Future<CoreFirebaseOptions> optionsFromResource() {
    throw UnimplementedError();
  }
}

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
    // `firebase_core_platform_interface` keeps initialized apps in static
    // state shared across the whole test isolate; reset it so every test
    // starts from "Firebase never initialized", regardless of run order.
    MethodChannelFirebase.appInstances.clear();
    MethodChannelFirebase.isCoreInitialized = false;
    TestFirebaseCoreHostApi.setUp(null);
    await resetDependencies();
  });

  testWidgets(
    'bootstrap initializes Firebase exactly once and renders VestiProApp',
    (tester) async {
      final fakeApi = _FakeFirebaseCoreHostApi();
      TestFirebaseCoreHostApi.setUp(fakeApi);

      await bootstrap(AppEnvironment.development);
      await tester.pumpAndSettle();

      expect(fakeApi.initializeAppCallCount, 1);
      expect(Firebase.apps, hasLength(1));
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.text('VestiPro Dev'), findsWidgets);
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
