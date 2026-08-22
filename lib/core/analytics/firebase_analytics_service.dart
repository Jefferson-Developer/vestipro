import 'dart:developer' as developer;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:injectable/injectable.dart';

import 'analytics_service.dart';

/// [AnalyticsService] backed by the real Firebase Analytics SDK.
///
/// Defensive by design: every public method swallows any error the
/// underlying SDK itself throws (logging it locally instead) so that a
/// broken analytics call never becomes the reason the app crashes (same
/// reasoning as `FirebaseCrashReporter`, TASK-016).
@LazySingleton(as: AnalyticsService)
final class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService(this._analytics);

  final FirebaseAnalytics _analytics;

  @override
  Future<void> logEvent(String name, {Map<String, Object?>? parameters}) {
    // `firebase_analytics` requires non-null parameter values (it asserts
    // each value is a String or num); this app's abstraction allows callers
    // to pass `null` for an absent/unknown value, so nulls are stripped here
    // instead of leaking that SDK constraint into every call site.
    final sanitizedParameters = parameters == null
        ? null
        : Map<String, Object>.fromEntries(
            parameters.entries
                .where((entry) => entry.value != null)
                .map((entry) => MapEntry(entry.key, entry.value!)),
          );

    return _guard(
      () => _analytics.logEvent(name: name, parameters: sanitizedParameters),
    );
  }

  @override
  Future<void> setUserId(String? userId) {
    return _guard(() => _analytics.setUserId(id: userId));
  }

  @override
  Future<void> setUserProperty({required String name, required String? value}) {
    return _guard(() => _analytics.setUserProperty(name: name, value: value));
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (error, stackTrace) {
      developer.log(
        'AnalyticsService failed to report an event.',
        name: 'vestipro.analytics_service',
        level: 900,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
