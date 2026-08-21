import 'package:cloud_functions/cloud_functions.dart';

import '../environment/app_environment.dart';
import '../environment/firebase_emulator_host.dart';
import '../environment/firebase_emulator_ports.dart';

/// For every non-`prod` flavor, connects [functions] to the local Functions
/// Emulator (ADR-0002) — the Functions counterpart of `configureFirestore`
/// (TASK-013) and `configureStorage` (TASK-014).
///
/// Must run before any other call on [functions]. Called once, from the
/// `FirebaseFunctions` DI provider (`lib/app/injection_module.dart`), so it
/// only runs when something actually resolves a Functions-backed dependency.
///
/// Unlike `configureStorage`'s `useStorageEmulator` (`Future<void>`),
/// `FirebaseFunctions.useFunctionsEmulator` is synchronous — nothing to
/// await here.
void configureFunctions(
  FirebaseFunctions functions, {
  required AppEnvironment environment,
}) {
  if (!environment.isProduction) {
    functions.useFunctionsEmulator(
      resolveFirebaseEmulatorHost(),
      FirebaseEmulatorPorts.functions,
    );
  }
}
