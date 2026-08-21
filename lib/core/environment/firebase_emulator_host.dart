import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Resolves the Firebase Emulator Suite host for the current platform.
///
/// The Android emulator cannot reach the host machine through `localhost`;
/// it requires the special alias `10.0.2.2`. Every other platform (iOS
/// simulator, desktop, web) reaches the host machine directly. Shared by
/// every SDK that connects to the Emulator Suite (TASK-012 Auth, TASK-013
/// Firestore, TASK-014 Storage, TASK-015 Functions).
String resolveFirebaseEmulatorHost() {
  if (kIsWeb) return 'localhost';
  if (Platform.isAndroid) return '10.0.2.2';
  return 'localhost';
}
