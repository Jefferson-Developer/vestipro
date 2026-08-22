import 'analytics_service.dart';

/// An event recorded by [FakeAnalyticsService.logEvent], kept for assertions
/// in tests.
final class LoggedAnalyticsEvent {
  const LoggedAnalyticsEvent(this.name, this.parameters);

  final String name;
  final Map<String, Object?>? parameters;

  @override
  String toString() => 'LoggedAnalyticsEvent($name, $parameters)';
}

/// In-memory [AnalyticsService] for unit/BLoC tests (TASK-017) — lets a use
/// case or BLoC that triggers analytics events be tested without depending
/// on the real `firebase_analytics` SDK or a platform channel mock.
///
/// Not gated behind `flutter_test`/`package:test` on purpose: it has no
/// dependency beyond this package's own `AnalyticsService` contract, so it
/// can be reused directly from `test/` across features without needing a
/// `mocktail` `Mock` boilerplate for the common case of "assert an event was
/// logged with these parameters".
final class FakeAnalyticsService implements AnalyticsService {
  final List<LoggedAnalyticsEvent> loggedEvents = [];
  final Map<String, String?> userProperties = {};
  String? userId;

  @override
  Future<void> logEvent(String name, {Map<String, Object?>? parameters}) async {
    loggedEvents.add(LoggedAnalyticsEvent(name, parameters));
  }

  @override
  Future<void> setUserId(String? userId) async {
    this.userId = userId;
  }

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    userProperties[name] = value;
  }

  /// Clears every recorded event/property — useful between test cases that
  /// reuse the same fake instance.
  void reset() {
    loggedEvents.clear();
    userProperties.clear();
    userId = null;
  }
}
