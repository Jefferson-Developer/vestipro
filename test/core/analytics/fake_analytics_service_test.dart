import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';

/// Stand-in for a future use case/BLoC that fires an analytics event on
/// login and logout, exercising [FakeAnalyticsService] the way real feature
/// tests will (TASK-017 test requirement: "validando que logEvent é chamado
/// com o nome e parâmetros corretos a partir de um ponto de disparo de
/// exemplo").
class _LoginAnalyticsExample {
  const _LoginAnalyticsExample(this._analytics);

  final AnalyticsService _analytics;

  Future<void> onLoginCompleted({
    required String userId,
    required String organizationId,
    required String role,
  }) async {
    await _analytics.setUserId(userId);
    await _analytics.setUserProperty(
      name: AnalyticsUserProperties.organizationId,
      value: organizationId,
    );
    await _analytics.setUserProperty(
      name: AnalyticsUserProperties.role,
      value: role,
    );
    await _analytics.logEvent(
      AnalyticsEvents.loginCompleted,
      parameters: {'method': 'password'},
    );
  }

  Future<void> onLogout() async {
    await _analytics.setUserId(null);
    await _analytics.setUserProperty(
      name: AnalyticsUserProperties.organizationId,
      value: null,
    );
    await _analytics.setUserProperty(
      name: AnalyticsUserProperties.role,
      value: null,
    );
  }
}

void main() {
  group('FakeAnalyticsService', () {
    late FakeAnalyticsService analytics;
    late _LoginAnalyticsExample example;

    setUp(() {
      analytics = FakeAnalyticsService();
      example = _LoginAnalyticsExample(analytics);
    });

    test('logEvent records the event name and parameters', () async {
      await example.onLoginCompleted(
        userId: 'user-123',
        organizationId: 'org-456',
        role: 'representative',
      );

      expect(analytics.loggedEvents, hasLength(1));
      final logged = analytics.loggedEvents.single;
      expect(logged.name, AnalyticsEvents.loginCompleted);
      expect(logged.parameters, {'method': 'password'});
    });

    test('setUserId/setUserProperty are recorded on login', () async {
      await example.onLoginCompleted(
        userId: 'user-123',
        organizationId: 'org-456',
        role: 'representative',
      );

      expect(analytics.userId, 'user-123');
      expect(
        analytics.userProperties[AnalyticsUserProperties.organizationId],
        'org-456',
      );
      expect(
        analytics.userProperties[AnalyticsUserProperties.role],
        'representative',
      );
    });

    test('setUserId/setUserProperty are cleared on logout', () async {
      await example.onLoginCompleted(
        userId: 'user-123',
        organizationId: 'org-456',
        role: 'representative',
      );

      await example.onLogout();

      expect(analytics.userId, isNull);
      expect(
        analytics.userProperties[AnalyticsUserProperties.organizationId],
        isNull,
      );
      expect(analytics.userProperties[AnalyticsUserProperties.role], isNull);
    });

    test('reset clears every recorded event/property', () async {
      await example.onLoginCompleted(
        userId: 'user-123',
        organizationId: 'org-456',
        role: 'representative',
      );

      analytics.reset();

      expect(analytics.loggedEvents, isEmpty);
      expect(analytics.userProperties, isEmpty);
      expect(analytics.userId, isNull);
    });
  });
}
