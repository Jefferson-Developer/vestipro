import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:injectable/injectable.dart';

import '../core/database/configure_firestore.dart';
import '../core/environment/app_environment.dart';
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

  @lazySingleton
  AboutAppSeedModel aboutAppSeedModel(AppEnvironment environment) {
    return AboutAppSeedModel.fromEnvironment(environment);
  }
}
