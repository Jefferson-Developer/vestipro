import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/dashboards/dashboards.dart';

void main() {
  group('ExecutiveDashboardMetric', () {
    test('available exposes value/previousValue and isAvailable', () {
      const metric = ExecutiveDashboardMetric.available(
        value: 150,
        previousValue: 100,
      );

      expect(metric.isAvailable, isTrue);
      expect(metric.status, ExecutiveDashboardMetricStatus.available);
      expect(metric.value, 150);
      expect(metric.previousValue, 100);
    });

    test('changePercentage computes the percentage variation', () {
      const metric = ExecutiveDashboardMetric.available(
        value: 150,
        previousValue: 100,
      );

      expect(metric.changePercentage, 50);
    });

    test('changePercentage handles a decrease as a negative percentage', () {
      const metric = ExecutiveDashboardMetric.available(
        value: 50,
        previousValue: 100,
      );

      expect(metric.changePercentage, -50);
    });

    test('changePercentage is null when previousValue is null (no '
        'comparison period available)', () {
      const metric = ExecutiveDashboardMetric.available(value: 150);

      expect(metric.changePercentage, isNull);
    });

    test('changePercentage is null when previousValue is zero, never a '
        'division-by-zero NaN/Infinity', () {
      const metric = ExecutiveDashboardMetric.available(
        value: 150,
        previousValue: 0,
      );

      expect(metric.changePercentage, isNull);
    });

    test('notCalculated has no value/previousValue and is never available', () {
      const metric = ExecutiveDashboardMetric.notCalculated();

      expect(metric.status, ExecutiveDashboardMetricStatus.notCalculated);
      expect(metric.isAvailable, isFalse);
      expect(metric.value, isNull);
      expect(metric.changePercentage, isNull);
    });

    test('failed carries the failure message and is never available', () {
      const metric = ExecutiveDashboardMetric.failed('boom');

      expect(metric.status, ExecutiveDashboardMetricStatus.failed);
      expect(metric.isAvailable, isFalse);
      expect(metric.failureMessage, 'boom');
      expect(metric.value, isNull);
    });

    test('equality/hashCode are value-based', () {
      expect(
        const ExecutiveDashboardMetric.available(value: 10, previousValue: 5),
        const ExecutiveDashboardMetric.available(value: 10, previousValue: 5),
      );
      expect(
        const ExecutiveDashboardMetric.notCalculated(),
        const ExecutiveDashboardMetric.notCalculated(),
      );
    });
  });
}
