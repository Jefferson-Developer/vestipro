import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/performance/performance.dart';

class _MockFirebasePerformance extends Mock implements FirebasePerformance {}

class _MockTrace extends Mock implements Trace {}

void main() {
  group('FirebasePerformanceMonitor', () {
    late _MockFirebasePerformance performance;
    late _MockTrace trace;
    late FirebasePerformanceMonitor monitor;

    setUp(() {
      performance = _MockFirebasePerformance();
      trace = _MockTrace();
      monitor = FirebasePerformanceMonitor(performance);

      when(() => performance.newTrace(any())).thenReturn(trace);
      when(() => trace.start()).thenAnswer((_) async {});
      when(() => trace.stop()).thenAnswer((_) async {});
      when(() => trace.putAttribute(any(), any())).thenReturn(null);
    });

    test('wrapAsync starts and stops the trace around the action', () async {
      final result = await monitor.wrapAsync(
        PerformanceTraces.catalogLoadDuration,
        () async => 42,
      );

      expect(result, 42);
      verify(
        () => performance.newTrace(PerformanceTraces.catalogLoadDuration),
      ).called(1);
      verify(() => trace.start()).called(1);
      verify(() => trace.stop()).called(1);
    });

    test(
      'wrapAsync stops the trace and rethrows when the action throws',
      () async {
        await expectLater(
          monitor.wrapAsync(
            PerformanceTraces.orderSubmitDuration,
            () async => throw Exception('boom'),
          ),
          throwsA(isA<Exception>()),
        );

        verify(() => trace.stop()).called(1);
      },
    );

    test('wrapAsync applies attributes before starting the trace', () async {
      await monitor.wrapAsync(
        PerformanceTraces.catalogLoadDuration,
        () async => 1,
        attributes: {'platform': 'android'},
      );

      verify(() => trace.putAttribute('platform', 'android')).called(1);
    });

    test("wrapAsync still runs and returns the action's result when the SDK "
        'fails to start the trace', () async {
      when(() => trace.start()).thenThrow(Exception('SDK unavailable'));

      final result = await monitor.wrapAsync(
        PerformanceTraces.orderSubmitDuration,
        () async => 'ok',
      );

      expect(result, 'ok');
      verifyNever(() => trace.stop());
    });

    test(
      'startTrace/stopTrace start and stop the underlying SDK trace',
      () async {
        await monitor.startTrace(PerformanceTraces.syncIncrementalDuration);
        await monitor.stopTrace(PerformanceTraces.syncIncrementalDuration);

        verify(() => trace.start()).called(1);
        verify(() => trace.stop()).called(1);
      },
    );

    test('stopTrace is a no-op when no matching trace was started', () async {
      await expectLater(monitor.stopTrace('never_started'), completes);
      verifyNever(() => trace.stop());
    });

    test(
      'never throws when the underlying SDK call fails (defensive coding)',
      () async {
        when(() => trace.start()).thenThrow(Exception('SDK unavailable'));
        when(() => trace.stop()).thenThrow(Exception('SDK unavailable'));

        await expectLater(
          monitor.startTrace(PerformanceTraces.syncIncrementalDuration),
          completes,
        );
        await expectLater(
          monitor.wrapAsync(
            PerformanceTraces.orderSubmitDuration,
            () async => 1,
          ),
          completes,
        );
      },
    );
  });
}
