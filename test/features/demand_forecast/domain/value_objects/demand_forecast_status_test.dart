import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/demand_forecast/demand_forecast.dart';

void main() {
  group('parseDemandForecastStatus', () {
    test('parses every known status code', () {
      expect(
        parseDemandForecastStatus('forecast'),
        DemandForecastStatus.forecast,
      );
      expect(
        parseDemandForecastStatus('insufficientData'),
        DemandForecastStatus.insufficientData,
      );
    });

    test('throws ArgumentError for an unknown status', () {
      expect(() => parseDemandForecastStatus('unknown'), throwsArgumentError);
    });
  });

  group('parseDemandForecastInsufficientDataReason', () {
    test('parses every known reason code', () {
      expect(
        parseDemandForecastInsufficientDataReason('noHistory'),
        DemandForecastInsufficientDataReason.noHistory,
      );
      expect(
        parseDemandForecastInsufficientDataReason('notEnoughHistory'),
        DemandForecastInsufficientDataReason.notEnoughHistory,
      );
    });

    test('throws ArgumentError for an unknown reason', () {
      expect(
        () => parseDemandForecastInsufficientDataReason('unknown'),
        throwsArgumentError,
      );
    });
  });
}
