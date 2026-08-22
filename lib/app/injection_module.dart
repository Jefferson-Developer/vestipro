import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:injectable/injectable.dart';

import '../core/database/configure_firestore.dart';
import '../core/environment/app_environment.dart';
import '../core/functions/configure_functions.dart';
import '../core/services/configure_crashlytics.dart';
import '../core/storage/configure_storage.dart';
import '../features/settings/data/models/about_app_seed_model.dart';

@module
abstract class AppInjectionModule {
  @lazySingleton
  AppEnvironment get appEnvironment => AppEnvironment.current;

  @lazySingleton
  FirebaseAuth get firebaseAuth => FirebaseAuth.instance;

  /// Configures native persistence and the Firestore Emulator connection
  /// (TASK-013) the first time something resolves [FirebaseFirestore] — not
  /// in `bootstrap.dart`, for the same reason `FirebaseAuthDataSource` does
  /// its own emulator wiring instead of bootstrap (TASK-012): no widget test
  /// that never touches Firestore should pay for it.
  @lazySingleton
  FirebaseFirestore firebaseFirestore(AppEnvironment environment) {
    final firestore = FirebaseFirestore.instance;
    configureFirestore(firestore, environment: environment);
    return firestore;
  }

  /// Connects to the Storage Emulator (TASK-014) the first time something
  /// resolves [FirebaseStorage] — same lazy-DI-triggered wiring rationale as
  /// [firebaseFirestore] above.
  @lazySingleton
  FirebaseStorage firebaseStorage(AppEnvironment environment) {
    final storage = FirebaseStorage.instance;
    configureStorage(storage, environment: environment);
    return storage;
  }

  /// Connects to the Functions Emulator (TASK-015) the first time something
  /// resolves [FirebaseFunctions] — same lazy-DI-triggered wiring rationale
  /// as [firebaseFirestore]/[firebaseStorage] above.
  @lazySingleton
  FirebaseFunctions firebaseFunctions(AppEnvironment environment) {
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

  @lazySingleton
  AboutAppSeedModel aboutAppSeedModel(AppEnvironment environment) {
    return AboutAppSeedModel.fromEnvironment(environment);
  }
}
