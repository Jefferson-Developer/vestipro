import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/demand_forecast/demand_forecast.dart';

void main() {
  group('parseDemandForecastScopeType', () {
    test('parses every known scope type code', () {
      expect(
        parseDemandForecastScopeType('product'),
        DemandForecastScopeType.product,
      );
      expect(
        parseDemandForecastScopeType('collection'),
        DemandForecastScopeType.collection,
      );
      expect(
        parseDemandForecastScopeType('region'),
        DemandForecastScopeType.region,
      );
    });

    test('throws ArgumentError for an unknown scope type', () {
      expect(
        () => parseDemandForecastScopeType('unknown'),
        throwsArgumentError,
      );
    });
  });

  group('DemandForecastScopeTypeCode.code', () {
    test('round-trips every scope type through parse', () {
      for (final scopeType in DemandForecastScopeType.values) {
        expect(parseDemandForecastScopeType(scopeType.code), scopeType);
      }
    });
  });
}
