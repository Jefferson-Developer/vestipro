import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/performance/performance.dart';

void main() {
  group('FakePerformanceMonitor', () {
    late FakePerformanceMonitor monitor;

    setUp(() {
      monitor = FakePerformanceMonitor();
    });

    test('startTrace/stopTrace record the trace name', () async {
      await monitor.startTrace(
        PerformanceTraces.catalogLoadDuration,
        attributes: {'platform': 'android'},
      );
      await monitor.stopTrace(PerformanceTraces.catalogLoadDuration);

      expect(monitor.startedTraces, hasLength(1));
      expect(
        monitor.startedTraces.single.name,
        PerformanceTraces.catalogLoadDuration,
      );
      expect(monitor.startedTraces.single.attributes, {'platform': 'android'});
      expect(monitor.stoppedTraces, [PerformanceTraces.catalogLoadDuration]);
    });

    test(
      'wrapAsync records start/stop and returns the action result',
      () async {
        final result = await monitor.wrapAsync(
          PerformanceTraces.orderSubmitDuration,
          () async => 'order-1',
        );

        expect(result, 'order-1');
        expect(
          monitor.startedTraces.single.name,
          PerformanceTraces.orderSubmitDuration,
        );
        expect(monitor.stoppedTraces, [PerformanceTraces.orderSubmitDuration]);
      },
    );

    test(
      'wrapAsync records stop and rethrows when the action throws',
      () async {
        await expectLater(
          monitor.wrapAsync(
            PerformanceTraces.orderSubmitDuration,
            () async => throw Exception('boom'),
          ),
          throwsA(isA<Exception>()),
        );

        expect(monitor.stoppedTraces, [PerformanceTraces.orderSubmitDuration]);
      },
    );

    test('reset clears every recorded trace', () async {
      await monitor.startTrace(PerformanceTraces.syncIncrementalDuration);
      await monitor.stopTrace(PerformanceTraces.syncIncrementalDuration);

      monitor.reset();

      expect(monitor.startedTraces, isEmpty);
      expect(monitor.stoppedTraces, isEmpty);
    });
  });
}
