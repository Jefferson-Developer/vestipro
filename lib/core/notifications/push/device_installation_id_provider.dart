import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Resolves a stable id for *this app installation* — never the FCM token
/// itself (which rotates), never a hardware id (privacy-invasive and
/// unnecessary here) — used as [PushDevice.id] so a token refresh
/// overwrites the same document instead of creating a new one every time
/// (TASK-150).
abstract interface class DeviceInstallationIdProvider {
  Future<String> resolve();
}

/// Generates the id once (via the already-registered [Uuid] dependency) and
/// persists it locally, reusing the same value for the lifetime of this app
/// installation (cleared only by an app uninstall/data wipe, same as any
/// other `SharedPreferences`-backed value in this codebase).
@LazySingleton(as: DeviceInstallationIdProvider)
final class SharedPreferencesDeviceInstallationIdProvider
    implements DeviceInstallationIdProvider {
  SharedPreferencesDeviceInstallationIdProvider(this._uuid);

  final Uuid _uuid;

  static const _key = 'push_device_installation_id';

  String? _cached;

  @override
  Future<String> resolve() async {
    final cached = _cached;
    if (cached != null) return cached;

    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key);
    if (existing != null && existing.isNotEmpty) {
      _cached = existing;
      return existing;
    }

    final generated = _uuid.v4();
    await prefs.setString(_key, generated);
    _cached = generated;
    return generated;
  }
}
