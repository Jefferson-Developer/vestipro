import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/environment/app_environment.dart';
import 'package:vestipro/core/performance/performance.dart';

class _MockFirebasePerformance extends Mock implements FirebasePerformance {}

void main() {
  group('configurePerformance', () {
    late _MockFirebasePerformance performance;

    setUp(() {
      performance = _MockFirebasePerformance();
      when(
        () => performance.setPerformanceCollectionEnabled(any()),
      ).thenAnswer((_) async {});
    });

    test('disables collection for development', () async {
      await configurePerformance(
        performance,
        environment: AppEnvironment.development,
      );

      verify(
        () => performance.setPerformanceCollectionEnabled(false),
      ).called(1);
    });

    test('enables collection for staging', () async {
      await configurePerformance(
        performance,
        environment: AppEnvironment.staging,
      );

      verify(() => performance.setPerformanceCollectionEnabled(true)).called(1);
    });

    test('enables collection for production', () async {
      await configurePerformance(
        performance,
        environment: AppEnvironment.production,
      );

      verify(() => performance.setPerformanceCollectionEnabled(true)).called(1);
    });

    test(
      'never throws when the underlying SDK call fails (defensive coding)',
      () async {
        when(
          () => performance.setPerformanceCollectionEnabled(any()),
        ).thenThrow(Exception('SDK unavailable'));

        await expectLater(
          configurePerformance(
            performance,
            environment: AppEnvironment.development,
          ),
          completes,
        );
      },
    );
  });
}
