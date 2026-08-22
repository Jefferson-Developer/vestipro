import 'dart:developer' as developer;

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:injectable/injectable.dart';

import 'feature_flag_registry.dart';
import 'feature_flag_service.dart';

/// [FeatureFlagService] backed by the real Firebase Remote Config SDK
/// (TASK-018).
///
/// Defensive by design, same reasoning as `FirebaseAnalyticsService`
/// (TASK-017) and `FirebaseCrashReporter` (TASK-016): every public method
/// swallows any error the underlying SDK throws and returns the flag's
/// code-defined default from [FeatureFlagRegistry] instead, so a broken/
/// unreachable Remote Config backend (or an app still mid-bootstrap, before
/// `configureRemoteConfig`'s `setDefaults` call has completed) never
/// crashes the app nor blocks the caller.
///
/// Beyond error handling, [_read] also treats
/// [ValueSource.valueStatic] (the SDK's own raw built-in default, returned
/// before `setDefaults`/a fetch has ever applied a value for a key) the
/// same as a thrown error: it falls back to the registry default rather
/// than trusting the SDK's un-configured value. This is what keeps flag
/// reads correct even if something reads a flag while
/// `configureRemoteConfig`'s `setDefaults` call (fired, but not awaited, by
/// the `FirebaseRemoteConfig` DI provider) is still in flight.
@LazySingleton(as: FeatureFlagService)
final class FirebaseFeatureFlagService implements FeatureFlagService {
  FirebaseFeatureFlagService(this._remoteConfig);

  final FirebaseRemoteConfig _remoteConfig;

  @override
  bool isEnabled(String flagKey) {
    final definition = FeatureFlagRegistry.definitionOf(flagKey);
    return _read<bool>(
      flagKey,
      _remoteConfig.getBool,
      definition.defaultValue as bool,
    );
  }

  @override
  String getString(String flagKey) {
    final definition = FeatureFlagRegistry.definitionOf(flagKey);
    return _read<String>(
      flagKey,
      _remoteConfig.getString,
      definition.defaultValue as String,
    );
  }

  @override
  int getInt(String flagKey) {
    final definition = FeatureFlagRegistry.definitionOf(flagKey);
    return _read<int>(
      flagKey,
      _remoteConfig.getInt,
      definition.defaultValue as int,
    );
  }

  T _read<T>(String flagKey, T Function(String) read, T fallback) {
    try {
      if (_remoteConfig.getValue(flagKey).source == ValueSource.valueStatic) {
        return fallback;
      }
      return read(flagKey);
    } catch (error, stackTrace) {
      developer.log(
        'FeatureFlagService failed to read "$flagKey"; using local default.',
        name: 'vestipro.feature_flags',
        level: 900,
        error: error,
        stackTrace: stackTrace,
      );
      return fallback;
    }
  }
}
