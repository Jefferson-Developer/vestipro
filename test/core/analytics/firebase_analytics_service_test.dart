import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';

class _MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

void main() {
  group('FirebaseAnalyticsService', () {
    late _MockFirebaseAnalytics firebaseAnalytics;
    late FirebaseAnalyticsService service;

    setUp(() {
      firebaseAnalytics = _MockFirebaseAnalytics();
      service = FirebaseAnalyticsService(firebaseAnalytics);

      when(
        () => firebaseAnalytics.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => firebaseAnalytics.setUserId(id: any(named: 'id')),
      ).thenAnswer((_) async {});
      when(
        () => firebaseAnalytics.setUserProperty(
          name: any(named: 'name'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
    });

    test('logEvent forwards the name and parameters to the SDK', () async {
      await service.logEvent(
        AnalyticsEvents.customerCreated,
        parameters: {'source': 'catalog'},
      );

      verify(
        () => firebaseAnalytics.logEvent(
          name: AnalyticsEvents.customerCreated,
          parameters: {'source': 'catalog'},
        ),
      ).called(1);
    });

    test(
      'logEvent strips null parameter values before calling the SDK',
      () async {
        await service.logEvent(
          AnalyticsEvents.orderCreated,
          parameters: {'order_id': 'order-1', 'discount': null},
        );

        verify(
          () => firebaseAnalytics.logEvent(
            name: AnalyticsEvents.orderCreated,
            parameters: {'order_id': 'order-1'},
          ),
        ).called(1);
      },
    );

    test('setUserId forwards to the SDK, including null to clear it', () async {
      await service.setUserId('user-123');
      verify(() => firebaseAnalytics.setUserId(id: 'user-123')).called(1);

      await service.setUserId(null);
      verify(() => firebaseAnalytics.setUserId(id: null)).called(1);
    });

    test('setUserProperty forwards to the SDK', () async {
      await service.setUserProperty(
        name: AnalyticsUserProperties.role,
        value: 'representative',
      );

      verify(
        () => firebaseAnalytics.setUserProperty(
          name: AnalyticsUserProperties.role,
          value: 'representative',
        ),
      ).called(1);
    });

    test(
      'never throws when the underlying SDK call fails (defensive coding)',
      () async {
        when(
          () => firebaseAnalytics.logEvent(
            name: any(named: 'name'),
            parameters: any(named: 'parameters'),
          ),
        ).thenThrow(Exception('SDK unavailable'));
        when(
          () => firebaseAnalytics.setUserId(id: any(named: 'id')),
        ).thenThrow(Exception('SDK unavailable'));
        when(
          () => firebaseAnalytics.setUserProperty(
            name: any(named: 'name'),
            value: any(named: 'value'),
          ),
        ).thenThrow(Exception('SDK unavailable'));

        await expectLater(
          service.logEvent(AnalyticsEvents.orderCreated),
          completes,
        );
        await expectLater(service.setUserId('user-123'), completes);
        await expectLater(
          service.setUserProperty(
            name: AnalyticsUserProperties.role,
            value: 'x',
          ),
          completes,
        );
      },
    );
  });
}
