import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which `organizationId`/`userId` this device most recently registered a
/// [PushDevice] for, plus the local [DeviceInstallationIdProvider] id used
/// at the time.
final class PushRegistrationRecord {
  const PushRegistrationRecord({
    required this.organizationId,
    required this.userId,
    required this.deviceId,
  });

  final String organizationId;
  final String userId;
  final String deviceId;
}

/// Remembers the last successful push registration purely so
/// `PushTokenService.unregisterCurrentDevice` (logout) and the FCM
/// `onTokenRefresh` handler know what/who to act on, without depending on
/// any session or organization context still being available at that
/// moment (TASK-150) — logout already clears the session before anything
/// else runs, and a background token refresh has no session context at all.
abstract interface class PushRegistrationLocalStore {
  Future<void> save(PushRegistrationRecord record);

  Future<PushRegistrationRecord?> read();

  Future<void> clear();
}

@LazySingleton(as: PushRegistrationLocalStore)
final class SharedPreferencesPushRegistrationLocalStore
    implements PushRegistrationLocalStore {
  static const _organizationIdKey = 'push_registration_organization_id';
  static const _userIdKey = 'push_registration_user_id';
  static const _deviceIdKey = 'push_registration_device_id';

  @override
  Future<void> save(PushRegistrationRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_organizationIdKey, record.organizationId);
    await prefs.setString(_userIdKey, record.userId);
    await prefs.setString(_deviceIdKey, record.deviceId);
  }

  @override
  Future<PushRegistrationRecord?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final organizationId = prefs.getString(_organizationIdKey);
    final userId = prefs.getString(_userIdKey);
    final deviceId = prefs.getString(_deviceIdKey);
    if (organizationId == null || userId == null || deviceId == null) {
      return null;
    }
    return PushRegistrationRecord(
      organizationId: organizationId,
      userId: userId,
      deviceId: deviceId,
    );
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_organizationIdKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_deviceIdKey);
  }
}
