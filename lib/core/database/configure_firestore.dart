import 'package:cloud_firestore/cloud_firestore.dart';

import '../environment/app_environment.dart';
import '../environment/firebase_emulator_host.dart';
import '../environment/firebase_emulator_ports.dart';

/// Enables Firestore's native offline persistence and, for every non-`prod`
/// flavor, connects [firestore] to the local Firestore Emulator (ADR-0002) —
/// the Firestore counterpart of `FirebaseAuthDataSource`'s emulator wiring
/// (TASK-012).
///
/// Must run before any other call on [firestore]. Called once, from the
/// `FirebaseFirestore` DI provider (`lib/app/injection_module.dart`), so it
/// only runs when something actually resolves a Firestore-backed dependency
/// — no feature does yet, so this has no effect on app boot until one does.
void configureFirestore(
  FirebaseFirestore firestore, {
  required AppEnvironment environment,
}) {
  firestore.settings = const Settings(persistenceEnabled: true);

  if (!environment.isProduction) {
    firestore.useFirestoreEmulator(
      resolveFirebaseEmulatorHost(),
      FirebaseEmulatorPorts.firestore,
    );
  }
}
