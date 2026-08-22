import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/feature_flags/feature_flags.dart';

void main() {
  group('FeatureFlagRegistry', () {
    test('every registered flag has an owner, review date and no key '
        'duplicates', () {
      final keys = FeatureFlagRegistry.all.map((definition) => definition.key);

      expect(keys.toSet().length, keys.length);

      for (final definition in FeatureFlagRegistry.all) {
        expect(definition.owner, isNotEmpty);
        expect(
          definition.reviewBy.isAfter(definition.createdAt),
          isTrue,
          reason:
              '${definition.key} must have a review date after its '
              'creation date',
        );
      }
    });

    test('exposes the example flag created for TASK-018', () {
      final definition = FeatureFlagRegistry.definitionOf(
        FeatureFlagRegistry.featureInsightsEnabled,
      );

      expect(definition.type, FeatureFlagValueType.boolean);
      expect(definition.defaultValue, isFalse);
    });

    test('remoteConfigDefaults has one entry per registered flag', () {
      expect(
        FeatureFlagRegistry.remoteConfigDefaults.length,
        FeatureFlagRegistry.all.length,
      );
      expect(
        FeatureFlagRegistry.remoteConfigDefaults[FeatureFlagRegistry
            .featureInsightsEnabled],
        false,
      );
    });

    test('definitionOf throws for an unregistered key', () {
      expect(
        () => FeatureFlagRegistry.definitionOf('feature_never_registered'),
        throwsArgumentError,
      );
    });
  });
}
