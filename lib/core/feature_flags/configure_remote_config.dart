import 'dart:async' show Future;
import 'dart:developer' as developer;

import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../environment/app_environment.dart';
import 'feature_flag_registry.dart';

/// Extra guard applied on top of `fetchAndActivate()` itself, in addition to
/// [RemoteConfigSettings.fetchTimeout] — belt-and-suspenders so a slow or
/// unreachable Remote Config backend can never delay [configureRemoteConfig]
/// beyond this, on every platform (TASK-018).
const Duration remoteConfigFetchGuardTimeout = Duration(seconds: 10);

/// Configures [remoteConfig] with a per-[environment] fetch policy and safe
/// local defaults (TASK-018) — the Remote Config counterpart of
/// `configureFirestore` (TASK-013), `configureStorage` (TASK-014) and
/// `configureFunctions` (TASK-015), except there is no local Remote Config
/// Emulator to connect to (same limitation as `configureCrashlytics`,
/// TASK-016).
///
/// Order matters and is awaited end-to-end by this function on purpose:
///
/// 1. `setConfigSettings` first, so every fetch/activate call below (and any
///    later one triggered elsewhere in the app) already uses the right
///    per-environment fetch policy ([_minimumFetchIntervalFor]).
/// 2. `setDefaults` next, with every flag/parameter registered in
///    [FeatureFlagRegistry] — this is what lets `FirebaseFeatureFlagService`
///    tell "Remote Config has a real value for this key" apart from "the
///    SDK's own un-configured built-in default" (see its `_read`).
/// 3. `fetchAndActivate` last, best-effort: guarded by
///    [remoteConfigFetchGuardTimeout] on top of the SDK's own
///    `fetchTimeout`.
///
/// Never throws: every step is wrapped in `try`/`catch`, because this is
/// called fire-and-forget (`unawaited`) from the `FirebaseRemoteConfig` DI
/// provider (`lib/app/injection_module.dart`) — nothing downstream ever
/// awaits or catches this Future, so it must never complete with an error.
/// A failure at any step simply means the app keeps running on the safe
/// code-defined defaults from [FeatureFlagRegistry], exactly as required by
/// `AGENTS.md` ("fetch never blocks app load, always falls back to local
/// defaults").
Future<void> configureRemoteConfig(
  FirebaseRemoteConfig remoteConfig, {
  required AppEnvironment environment,
}) async {
  try {
    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: _minimumFetchIntervalFor(environment),
      ),
    );
    await remoteConfig.setDefaults(FeatureFlagRegistry.remoteConfigDefaults);
  } catch (error, stackTrace) {
    developer.log(
      'configureRemoteConfig failed to apply fetch settings/defaults; '
      'flags will still fall back to their code-defined default.',
      name: 'vestipro.feature_flags',
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
    return;
  }

  try {
    await remoteConfig.fetchAndActivate().timeout(
      remoteConfigFetchGuardTimeout,
    );
  } catch (error, stackTrace) {
    developer.log(
      'configureRemoteConfig failed to fetch remote values; keeping local '
      'defaults.',
      name: 'vestipro.feature_flags',
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
  }
}

/// Per-environment cache staleness policy: aggressive in `development` (a
/// flag change in the console/Emulator becomes visible on the very next
/// fetch, without waiting out a cache window during active development),
/// progressively more conservative in `staging`/`production` (so the app
/// does not hammer the Remote Config backend with every cold start across
/// the whole install base).
Duration _minimumFetchIntervalFor(AppEnvironment environment) {
  switch (environment.name) {
    case AppEnvironmentName.development:
      return Duration.zero;
    case AppEnvironmentName.staging:
      return const Duration(minutes: 15);
    case AppEnvironmentName.production:
      return const Duration(hours: 1);
  }
}
