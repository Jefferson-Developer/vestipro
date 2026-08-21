import 'dart:async' show unawaited;

import 'package:firebase_storage/firebase_storage.dart';

import '../environment/app_environment.dart';
import '../environment/firebase_emulator_host.dart';
import '../environment/firebase_emulator_ports.dart';

/// For every non-`prod` flavor, connects [storage] to the local Storage
/// Emulator (ADR-0002) — the Storage counterpart of `configureFirestore`
/// (TASK-013) and `FirebaseAuthDataSource`'s emulator wiring (TASK-012).
///
/// Must run before any other call on [storage]. Called once, from the
/// `FirebaseStorage` DI provider (`lib/app/injection_module.dart`), so it
/// only runs when something actually resolves a Storage-backed dependency.
///
/// Unlike `configureFirestore`'s `useFirestoreEmulator` (sync),
/// `FirebaseStorage.useStorageEmulator` is `Future<void>`. It is
/// intentionally not awaited here, for the same reason
/// `FirebaseAuthDataSource` does not await `useAuthEmulator` (TASK-012): this
/// function stays synchronous so it can run eagerly as soon as
/// `FirebaseStorage` is resolved, before any real network call is made —
/// callers that exercise the real emulator (see the integration test) run
/// slower setup first, which gives this call time to land.
void configureStorage(
  FirebaseStorage storage, {
  required AppEnvironment environment,
}) {
  if (!environment.isProduction) {
    unawaited(
      storage.useStorageEmulator(
        resolveFirebaseEmulatorHost(),
        FirebaseEmulatorPorts.storage,
      ),
    );
  }
}
