import 'dart:developer' as developer;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:injectable/injectable.dart';

import '../environment/app_environment.dart';
import '../functions/app_client_metadata.dart';
import 'crash_reporter.dart';

/// [CrashReporter] backed by the real Firebase Crashlytics SDK.
///
/// Defensive by design: every public method swallows any error the
/// underlying SDK itself throws (logging it locally instead) so that a
/// broken crash-reporting call never becomes the reason the app crashes.
@LazySingleton(as: CrashReporter)
final class FirebaseCrashReporter implements CrashReporter {
  FirebaseCrashReporter(
    this._crashlytics,
    this._environment,
    this._metadataProvider,
  );

  final FirebaseCrashlytics _crashlytics;
  final AppEnvironment _environment;
  final AppClientMetadataProvider _metadataProvider;

  bool _baseContextAttached = false;

  @override
  Future<void> recordError(
    Object exception,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    // Attaching context and recording the error are guarded independently:
    // a failure while attaching context (e.g. a transient SDK glitch) must
    // never swallow the actual error report.
    await _guard(_ensureBaseContext);
    await _guard(
      () => _crashlytics.recordError(
        exception,
        stackTrace,
        reason: reason,
        fatal: fatal,
      ),
    );
  }

  @override
  Future<void> setUserIdentifier(String? userId) {
    return _guard(() => _crashlytics.setUserIdentifier(userId ?? ''));
  }

  @override
  Future<void> setCustomKey(String key, Object value) {
    return _guard(() => _crashlytics.setCustomKey(key, value));
  }

  /// Attaches safe, non-personal context (environment, app version,
  /// platform) once, the first time an error is actually reported — never
  /// eagerly at app startup, so a build/test that never triggers a crash
  /// report never has to pay for touching the Crashlytics plugin channel.
  Future<void> _ensureBaseContext() async {
    if (_baseContextAttached) return;
    _baseContextAttached = true;

    await _crashlytics.setCustomKey('environment', _environment.value);
    final metadata = await _metadataProvider.resolve();
    await _crashlytics.setCustomKey('appVersion', metadata.appVersion);
    await _crashlytics.setCustomKey('platform', metadata.platform);
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (error, stackTrace) {
      developer.log(
        'CrashReporter failed to report an error.',
        name: 'vestipro.crash_reporter',
        level: 900,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
