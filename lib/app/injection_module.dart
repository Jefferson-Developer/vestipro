import 'dart:async' show unawaited;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

import '../core/analytics/configure_analytics.dart';
import '../core/database/app_database.dart';
import '../core/database/configure_firestore.dart';
import '../core/environment/app_environment.dart';
import '../core/feature_flags/configure_remote_config.dart';
import '../core/functions/configure_functions.dart';
import '../core/performance/configure_performance.dart';
import '../core/security/configure_app_check.dart';
import '../core/services/configure_crashlytics.dart';
import '../core/storage/configure_storage.dart';
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

  /// Toggles Crashlytics collection (TASK-016) the first time something
  /// resolves [FirebaseCrashlytics] — same lazy-DI-triggered wiring
  /// rationale as [firebaseFirestore]/[firebaseStorage]/[firebaseFunctions]
  /// above. In practice, that first resolution only happens when an error is
  /// actually reported (see `FirebaseCrashReporter`).
  @lazySingleton
  FirebaseCrashlytics firebaseCrashlytics(AppEnvironment environment) {
    final crashlytics = FirebaseCrashlytics.instance;
    configureCrashlytics(crashlytics, environment: environment);
    return crashlytics;
  }

  /// Toggles Analytics collection and tags test/QA traffic (TASK-017) the
  /// first time something resolves [FirebaseAnalytics] — same lazy-DI-
  /// triggered wiring rationale as [firebaseCrashlytics] above.
  @lazySingleton
  FirebaseAnalytics firebaseAnalytics(AppEnvironment environment) {
    final analytics = FirebaseAnalytics.instance;
    configureAnalytics(analytics, environment: environment);
    return analytics;
  }

  /// Toggles Performance Monitoring collection (TASK-019) the first time
  /// something resolves [FirebasePerformance] — same lazy-DI-triggered
  /// wiring rationale as [firebaseCrashlytics]/[firebaseAnalytics] above.
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
  /// [firebaseStorage]/[firebaseFunctions]/[firebaseCrashlytics]/
  /// [firebaseAnalytics] above. `unawaited` here is safe:
  /// [configureRemoteConfig] never completes with an error (see its own
  /// docs), so this never blocks app bootstrap nor leaks an unhandled
  /// Future rejection.
  @lazySingleton
  FirebaseRemoteConfig firebaseRemoteConfig(AppEnvironment environment) {
    final remoteConfig = FirebaseRemoteConfig.instance;
    unawaited(configureRemoteConfig(remoteConfig, environment: environment));
    return remoteConfig;
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
  /// through `drift_flutter`. Web is not wired yet: `driftDatabase` requires
  /// bundled `sqlite3.wasm`/`drift_worker.js` assets that do not exist in
  /// this repository yet, so resolving [AppDatabase] on Web throws a clear
  /// `ArgumentError` until a later task (EPIC-14) adds those assets. Nothing
  /// resolves [AppDatabase] yet outside tests that provide their own
  /// in-memory instance, so this is a documented, currently-unreachable gap
  /// rather than a regression.
  @lazySingleton
  AppDatabase appDatabase() {
    return AppDatabase(driftDatabase(name: 'vestipro_offline'));
  }
}
