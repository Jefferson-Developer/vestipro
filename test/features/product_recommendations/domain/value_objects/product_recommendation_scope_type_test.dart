import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/product_recommendations/product_recommendations.dart';

void main() {
  group('ProductRecommendationScopeType', () {
    test('round-trips every known value through code/parse', () {
      for (final scopeType in ProductRecommendationScopeType.values) {
        expect(parseProductRecommendationScopeType(scopeType.code), scopeType);
      }
    });

    test('throws ArgumentError for an unknown value', () {
      expect(
        () => parseProductRecommendationScopeType('unknown'),
        throwsArgumentError,
      );
    });
  });
}
