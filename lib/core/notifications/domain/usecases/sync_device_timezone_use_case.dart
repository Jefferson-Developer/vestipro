import 'package:injectable/injectable.dart';

import '../../../utils/utils.dart';
import '../../push/device_timezone_provider.dart';
import '../entities/communication_preferences.dart';
import '../repositories/communication_preferences_repository.dart';

/// Keeps `CommunicationPreferences.quietHours.timezoneOffsetMinutes` in
/// sync with this device's own current UTC offset (TASK-155's "capturar e
/// persistir o timezone real do dispositivo do usuário... detectando a
/// mudança e atualizando o cadastro correspondente").
///
/// A no-op write whenever the offset already on file matches the device's
/// current one — the common case on every call after the first one on a
/// given day — so a normal session (no travel across timezones) never
/// writes this document repeatedly just because the app happened to
/// restart.
@injectable
final class SyncDeviceTimezoneUseCase {
  const SyncDeviceTimezoneUseCase(
    this._preferencesRepository,
    this._timezoneProvider,
  );

  final CommunicationPreferencesRepository _preferencesRepository;
  final DeviceTimezoneProvider _timezoneProvider;

  /// Best-effort by design (same convention every other session-lifecycle
  /// hook in `bootstrap.dart` already follows, e.g. push token
  /// registration): a read/write failure here must never surface anywhere
  /// else in the app, and simply leaves the previously-known offset (or
  /// `null`, before the very first successful sync) in place until the next
  /// call succeeds.
  Future<void> call({
    required String organizationId,
    required String userId,
  }) async {
    final currentOffsetMinutes = _timezoneProvider.currentOffsetMinutes();

    final result = await _preferencesRepository.get(
      organizationId: organizationId,
      userId: userId,
    );
    final preferences = switch (result) {
      AppSuccess<CommunicationPreferences>(value: final value) => value,
      AppFailure<CommunicationPreferences>() => null,
    };
    if (preferences == null) return;

    if (preferences.quietHours.timezoneOffsetMinutes == currentOffsetMinutes) {
      return;
    }

    await _preferencesRepository.save(
      preferences: preferences.withQuietHours(
        preferences.quietHours.copyWith(
          timezoneOffsetMinutes: currentOffsetMinutes,
          timezoneUpdatedAt: DateTime.now().toUtc(),
        ),
      ),
    );
  }
}
