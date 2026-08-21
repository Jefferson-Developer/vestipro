/// Firebase Emulator Suite ports. Must stay in sync with the `emulators`
/// block in `firebase.json`. Shared by every SDK that connects to the
/// Emulator Suite for `dev`/`staging` (ADR-0002): Auth (TASK-012), Firestore
/// (TASK-013), Storage (TASK-014) and Functions (TASK-015).
final class FirebaseEmulatorPorts {
  const FirebaseEmulatorPorts._();

  static const auth = 9099;
  static const firestore = 8080;
  static const storage = 9199;
  static const functions = 5001;
}
