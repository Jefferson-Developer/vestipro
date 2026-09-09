import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/product_recommendations/product_recommendations.dart';

void main() {
  group('ProductRecommendationReasonCode', () {
    test('round-trips every known value through code/parse', () {
      for (final reasonCode in ProductRecommendationReasonCode.values) {
        expect(
          parseProductRecommendationReasonCode(reasonCode.code),
          reasonCode,
        );
      }
    });

    test('throws ArgumentError for an unknown value', () {
      expect(
        () => parseProductRecommendationReasonCode('unknown'),
        throwsArgumentError,
      );
    });
  });
}
