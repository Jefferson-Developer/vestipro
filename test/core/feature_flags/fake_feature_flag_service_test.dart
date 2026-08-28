import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/feature_flags/feature_flags.dart';

void main() {
  group('FakeFeatureFlagService', () {
    test('returns the registry default when never overridden', () {
      final service = FakeFeatureFlagService();

      expect(
        service.isEnabled(FeatureFlagRegistry.featureInsightsEnabled),
        isFalse,
      );
    });

    test('overrideFlag changes the value returned for a key', () {
      final service = FakeFeatureFlagService();

      service.overrideFlag(FeatureFlagRegistry.featureInsightsEnabled, true);

      expect(
        service.isEnabled(FeatureFlagRegistry.featureInsightsEnabled),
        isTrue,
      );
    });

    test('constructor accepts initial overrides', () {
      final service = FakeFeatureFlagService(
        overrides: {FeatureFlagRegistry.featureInsightsEnabled: true},
      );

      expect(
        service.isEnabled(FeatureFlagRegistry.featureInsightsEnabled),
        isTrue,
      );
    });

    test('supports overriding the stock reservation flag', () {
      final service = FakeFeatureFlagService();

      service.overrideFlag(
        FeatureFlagRegistry.featureInventoryReservationsEnabled,
        true,
      );

      expect(
        service.isEnabled(
          FeatureFlagRegistry.featureInventoryReservationsEnabled,
        ),
        isTrue,
      );
    });

    test('reset clears overrides back to the registry default', () {
      final service = FakeFeatureFlagService(
        overrides: {FeatureFlagRegistry.featureInsightsEnabled: true},
      );

      service.reset();

      expect(
        service.isEnabled(FeatureFlagRegistry.featureInsightsEnabled),
        isFalse,
      );
    });

    test('reading an unregistered key throws, same as the real '
        'implementation', () {
      final service = FakeFeatureFlagService();

      expect(
        () => service.isEnabled('feature_never_registered'),
        throwsArgumentError,
      );
    });
  });
}
