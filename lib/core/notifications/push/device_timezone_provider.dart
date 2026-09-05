import 'package:injectable/injectable.dart';

/// Resolves this device's own current UTC offset (TASK-155) — never the
/// server's/backend's timezone. Kept as its own thin, injectable
/// abstraction (rather than every caller reaching for `DateTime.now()`
/// directly) purely so `SyncDeviceTimezoneUseCase` can be unit tested with a
/// deterministic, non-real offset instead of depending on whatever
/// timezone the test runner's own machine happens to be in.
abstract interface class DeviceTimezoneProvider {
  /// This device's current UTC offset, in minutes — positive east of UTC,
  /// negative west, matching `DateTime.timeZoneOffset.inMinutes`.
  int currentOffsetMinutes();
}

/// Backed by `DateTime.now().timeZoneOffset` — the standard library's own
/// notion of "this device's local time right now", already DST-aware for
/// wherever the device physically is, without any timezone-database
/// dependency (see `QuietHours`'s own doc for why one was not added).
@LazySingleton(as: DeviceTimezoneProvider)
final class SystemDeviceTimezoneProvider implements DeviceTimezoneProvider {
  const SystemDeviceTimezoneProvider();

  @override
  int currentOffsetMinutes() => DateTime.now().timeZoneOffset.inMinutes;
}
