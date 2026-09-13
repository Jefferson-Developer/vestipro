import 'dart:async' show unawaited;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../core/analytics/configure_analytics.dart';
import '../core/database/app_database.dart';
import '../core/database/configure_firestore.dart';
import '../core/environment/app_environment.dart';
import '../core/feature_flags/configure_remote_config.dart';
import '../core/functions/configure_functions.dart';
import '../core/notifications/push/configure_messaging.dart';
import '../core/performance/configure_performance.dart';
import '../core/security/configure_app_check.dart';
import '../core/storage/configure_storage.dart';
import '../core/sync/domain/sync_retry_policy.dart';
import '../features/settings/data/models/about_app_seed_model.dart';

@module
abstract class AppInjectionModule {
  @lazySingleton
  AppEnvironment get appEnvironment => AppEnvironment.current;

  @lazySingleton
  FirebaseAuth get firebaseAuth => FirebaseAuth.instance;

  /// Backs `SecureFlutterSessionStore` (TASK-041). Default options already
  /// map to Keychain (iOS/macOS), Keystore-backed EncryptedSharedPreferences
  /// (Android) and DPAPI (Windows) — no extra per-platform configuration
  /// needed for the minimal, non-token session metadata it persists.
  @lazySingleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage();

  /// Activates App Check (TASK-032) the first time something resolves
  /// [FirebaseAppCheck] — same lazy-DI-triggered wiring rationale as every
  /// other Firebase product provider in this module. Unlike those, this one
  /// is also declared as an (unused) parameter of [firebaseFirestore],
  /// [firebaseStorage] and [firebaseFunctions] below on purpose: `injectable`
  /// resolves constructor/function parameters before the function body that
  /// depends on them runs, so this guarantees App Check activation is always
  /// *requested* before any of those three SDKs is handed to a caller — and
  /// therefore before the app's first real Firestore/Storage/Functions call
  /// — without making app boot itself wait for activation to finish
  /// (`configureAppCheck` is fire-and-forget, same as
  /// [firebaseRemoteConfig]/[firebasePerformance] below).
  @lazySingleton
  FirebaseAppCheck firebaseAppCheck(AppEnvironment environment) {
    final appCheck = FirebaseAppCheck.instance;
    unawaited(configureAppCheck(appCheck, environment: environment));
    return appCheck;
  }

  /// Configures native persistence and the Firestore Emulator connection
  /// (TASK-013) the first time something resolves [FirebaseFirestore] — not
  /// in `bootstrap.dart`, for the same reason `FirebaseAuthDataSource` does
  /// its own emulator wiring instead of bootstrap (TASK-012): no widget test
  /// that never touches Firestore should pay for it. [FirebaseAppCheck] is
  /// requested (not otherwise used) so App Check activation is always
  /// triggered first — see [firebaseAppCheck] above.
  @lazySingleton
  FirebaseFirestore firebaseFirestore(
    AppEnvironment environment,
    // ignore: avoid_unused_constructor_parameters
    FirebaseAppCheck appCheck,
  ) {
    final firestore = FirebaseFirestore.instance;
    configureFirestore(firestore, environment: environment);
    return firestore;
  }

  /// Connects to the Storage Emulator (TASK-014) the first time something
  /// resolves [FirebaseStorage] — same lazy-DI-triggered wiring rationale as
  /// [firebaseFirestore] above, including the [FirebaseAppCheck] ordering
  /// dependency.
  @lazySingleton
  FirebaseStorage firebaseStorage(
    AppEnvironment environment,
    // ignore: avoid_unused_constructor_parameters
    FirebaseAppCheck appCheck,
  ) {
    final storage = FirebaseStorage.instance;
    configureStorage(storage, environment: environment);
    return storage;
  }

  /// Connects to the Functions Emulator (TASK-015) the first time something
  /// resolves [FirebaseFunctions] — same lazy-DI-triggered wiring rationale
  /// as [firebaseFirestore]/[firebaseStorage] above, including the
  /// [FirebaseAppCheck] ordering dependency.
  @lazySingleton
  FirebaseFunctions firebaseFunctions(
    AppEnvironment environment,
    // ignore: avoid_unused_constructor_parameters
    FirebaseAppCheck appCheck,
  ) {
    final functions = FirebaseFunctions.instance;
    configureFunctions(functions, environment: environment);
    return functions;
  }

  /// Toggles Analytics collection and tags test/QA traffic (TASK-017) the
  /// first time something resolves [FirebaseAnalytics] — same lazy-DI-
  /// triggered wiring rationale as the other Firebase product providers above.
  @lazySingleton
  FirebaseAnalytics firebaseAnalytics(AppEnvironment environment) {
    final analytics = FirebaseAnalytics.instance;
    configureAnalytics(analytics, environment: environment);
    return analytics;
  }

  /// Toggles Performance Monitoring collection (TASK-019) the first time
  /// something resolves [FirebasePerformance] — same lazy-DI-triggered
  /// wiring rationale as [firebaseAnalytics] above.
  /// `unawaited` here is safe for the same reason it is for
  /// [firebaseRemoteConfig]: [configurePerformance] never completes with an
  /// error.
  @lazySingleton
  FirebasePerformance firebasePerformance(AppEnvironment environment) {
    final performance = FirebasePerformance.instance;
    unawaited(configurePerformance(performance, environment: environment));
    return performance;
  }

  /// Applies the per-environment fetch policy and safe local defaults
  /// (TASK-018) the first time something resolves [FirebaseRemoteConfig] —
  /// same lazy-DI-triggered wiring rationale as [firebaseFirestore]/
  /// [firebaseStorage]/[firebaseFunctions]/[firebaseAnalytics] above.
  /// `unawaited` here is safe:
  /// [configureRemoteConfig] never completes with an error (see its own
  /// docs), so this never blocks app bootstrap nor leaks an unhandled
  /// Future rejection.
  @lazySingleton
  FirebaseRemoteConfig firebaseRemoteConfig(AppEnvironment environment) {
    final remoteConfig = FirebaseRemoteConfig.instance;
    unawaited(configureRemoteConfig(remoteConfig, environment: environment));
    return remoteConfig;
  }

  /// Sets up foreground presentation options (TASK-150) the first time
  /// something resolves [FirebaseMessaging] — same lazy-DI-triggered wiring
  /// rationale as every other Firebase product provider above.
  /// `onBackgroundMessage` is registered separately in `bootstrap.dart`
  /// (must happen unconditionally, as early as `Firebase.initializeApp`
  /// itself — not gated behind whether anything ever resolves this getter).
  @lazySingleton
  FirebaseMessaging firebaseMessaging() {
    final messaging = FirebaseMessaging.instance;
    unawaited(configureMessaging(messaging));
    return messaging;
  }

  @lazySingleton
  AboutAppSeedModel aboutAppSeedModel(AppEnvironment environment) {
    return AboutAppSeedModel.fromEnvironment(environment);
  }

  /// Opens the local offline database (TASK-054) the first time something
  /// resolves [AppDatabase] — same lazy-DI-triggered wiring rationale as the
  /// Firebase product providers above, so the widget-test-heavy app never
  /// pays for it unless a feature actually reads/writes offline data.
  ///
  /// Native platforms (Android/iOS/Windows/macOS/Linux) work out of the box
  /// through `drift_flutter`. Web uses Drift's bundled worker and sqlite wasm
  /// files copied into `web/`, so offline tables are persisted in the browser
  /// storage backend selected by Drift (OPFS when available, IndexedDB
  /// fallback otherwise).
  @lazySingleton
  AppDatabase appDatabase() {
    return AppDatabase(
      driftDatabase(
        name: 'vestipro_offline',
        web: DriftWebOptions(
          sqlite3Wasm: Uri.parse('sqlite3.wasm'),
          driftWorker: Uri.parse('drift_worker.js'),
        ),
      ),
    );
  }

  /// Backs `ConnectivityPlusService` (TASK-109) — same lazy-DI-triggered
  /// wiring rationale as every other third-party SDK singleton above.
  @lazySingleton
  Connectivity get connectivity => Connectivity();

  /// Backs `SyncEngine`'s default retry/backoff policy (TASK-109) —
  /// registered here, rather than left as a bare constructor default value,
  /// so it stays a single explicit, swappable-in-tests dependency like
  /// every other cross-cutting policy in this module.
  @lazySingleton
  SyncRetryPolicy get syncRetryPolicy => const SyncRetryPolicy();

  /// Backs every use case/service that generates its own entity id
  /// client-side (`ConflictResolutionService`, `CloudFunctionsService`,
  /// `SaveReportView` — TASK-145) — previously left as an unregistered
  /// constructor default, which `injectable_generator` still happily
  /// generated a `gh<Uuid>()` call for (see
  /// `TASK-145-implementar-visualizacoes-salvas-CONCLUIDA.md`), throwing at
  /// runtime the first time one of those was actually resolved through
  /// GetIt. Registering it here, like every other shared, stateless
  /// third-party dependency in this module, fixes that pre-existing gap for
  /// all of them at once.
  @lazySingleton
  Uuid get uuid => const Uuid();

  /// Backs `OrganizationReportBrandingDataSource` (TASK-148): a plain HTTP
  /// GET client for downloading a PDF report export's logo image from
  /// `OrganizationSettings.brandingLogoUrl` — the one dependency `dio` was
  /// already reserved for ("external REST integrations", see its own
  /// `pubspec.yaml` comment) but had never actually been used by any feature
  /// until now.
  @lazySingleton
  Dio get dio => Dio();
}
