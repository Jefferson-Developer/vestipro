import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:vestipro/firebase_options.dart';

/// Fake host API that mimics a real Firebase Core plugin: it answers with no
/// pre-existing native app (`initializeCore` returns an empty list, just
/// like a Flutter app with no `google-services.json`/`GoogleService-Info.plist`
/// bundled) and hands back whatever options the caller requests.
///
/// Shared by every widget test that renders `VestiProApp`/composes the real
/// DI graph directly (`test/widget_test.dart`, `test/app/bootstrap_test.dart`)
/// — since TASK-041 wired a real `SessionAuthGuard` (which resolves
/// `FirebaseAuth` transitively) as `VestiProApp`'s default guard, rendering
/// it now genuinely requires Firebase to be initialized first, exactly like
/// production `bootstrap()` already guarantees before `runApp`.
class FakeFirebaseCoreHostApi implements TestFirebaseCoreHostApi {
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

/// Registers [FakeFirebaseCoreHostApi] and calls the real
/// `Firebase.initializeApp` against it, so a test can render `VestiProApp`
/// (or call `bootstrap()`) without a real native Firebase plugin.
Future<FakeFirebaseCoreHostApi> setUpFakeFirebaseCore() async {
  final fakeApi = FakeFirebaseCoreHostApi();
  TestFirebaseCoreHostApi.setUp(fakeApi);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  return fakeApi;
}

/// Undoes [setUpFakeFirebaseCore], so the next test starts from "Firebase
/// never initialized" regardless of run order — `firebase_core_platform_interface`
/// keeps initialized apps in static state shared across the whole test
/// isolate.
void tearDownFakeFirebaseCore() {
  MethodChannelFirebase.appInstances.clear();
  MethodChannelFirebase.isCoreInitialized = false;
  TestFirebaseCoreHostApi.setUp(null);
}
