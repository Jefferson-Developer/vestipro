import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/environment/app_environment.dart';

class _MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

void main() {
  group('configureAnalytics', () {
    late _MockFirebaseAnalytics analytics;

    setUp(() {
      analytics = _MockFirebaseAnalytics();
      when(
        () => analytics.setAnalyticsCollectionEnabled(any()),
      ).thenAnswer((_) async {});
      when(
        () => analytics.setUserProperty(
          name: any(named: 'name'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
    });

    test('disables collection and tags test traffic for development', () async {
      configureAnalytics(analytics, environment: AppEnvironment.development);

      verify(() => analytics.setAnalyticsCollectionEnabled(false)).called(1);
      verify(
        () => analytics.setUserProperty(
          name: AnalyticsUserProperties.isTestAccount,
          value: 'true',
        ),
      ).called(1);
    });

    test('enables collection but tags test traffic for staging', () async {
      configureAnalytics(analytics, environment: AppEnvironment.staging);

      verify(() => analytics.setAnalyticsCollectionEnabled(true)).called(1);
      verify(
        () => analytics.setUserProperty(
          name: AnalyticsUserProperties.isTestAccount,
          value: 'true',
        ),
      ).called(1);
    });

    test(
      'enables collection and clears the test-account tag for production',
      () async {
        configureAnalytics(analytics, environment: AppEnvironment.production);

        verify(() => analytics.setAnalyticsCollectionEnabled(true)).called(1);
        verify(
          () => analytics.setUserProperty(
            name: AnalyticsUserProperties.isTestAccount,
            value: null,
          ),
        ).called(1);
      },
    );
  });
}
