import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/performance/performance.dart';

void main() {
  group('PerformanceTraces', () {
    test('values has no duplicates', () {
      expect(
        PerformanceTraces.values.toSet().length,
        PerformanceTraces.values.length,
      );
    });

    test('values matches the documented catalog', () {
      expect(PerformanceTraces.values, [
        PerformanceTraces.syncIncrementalDuration,
        PerformanceTraces.orderSubmitDuration,
        PerformanceTraces.catalogLoadDuration,
        PerformanceTraces.dependencyInjectionSetupDuration,
      ]);
    });

    test('covers the sync, order submission and catalog loading traces '
        'required by TASK-019', () {
      expect(
        PerformanceTraces.syncIncrementalDuration,
        'sync_incremental_duration',
      );
      expect(PerformanceTraces.orderSubmitDuration, 'order_submit_duration');
      expect(PerformanceTraces.catalogLoadDuration, 'catalog_load_duration');
    });
  });
}
