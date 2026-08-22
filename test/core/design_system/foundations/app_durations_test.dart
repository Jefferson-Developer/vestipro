import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

void main() {
  group('AppDurations', () {
    test('fast < standard < slow', () {
      expect(AppDurations.fast, lessThan(AppDurations.standard));
      expect(AppDurations.standard, lessThan(AppDurations.slow));
    });

    test('stays within a discrete-animation range (<= 400ms)', () {
      expect(
        AppDurations.slow.inMilliseconds,
        lessThanOrEqualTo(const Duration(milliseconds: 400).inMilliseconds),
      );
    });
  });
}
