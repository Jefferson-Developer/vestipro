import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/demand_forecast/demand_forecast.dart';

void main() {
  group('DemandForecastMapper', () {
    const mapper = DemandForecastMapper();

    test('maps a forecast payload to the domain entity', () {
      final dto = DemandForecastDto.fromJson(<String, dynamic>{
        'organizationId': 'org-1',
        'companyId': 'company-1',
        'scopeType': 'collection',
        'scopeId': 'collection-1',
        'scopeLabel': 'Verão 2026',
        'anchorMonthKey': '2026-08',
        'status': 'forecast',
        'insufficientDataReason': null,
        'observedPeriodsCount': 9,
        'model': 'holtLinearTrend',
        'modelVersion': 'holt-linear-trend-v1',
        'residualStdDev': 4.1,
        'history': <Map<String, dynamic>>[
          {'periodKey': '2026-08', 'quantity': 50, 'observed': true},
        ],
        'forecastPeriods': <Map<String, dynamic>>[
          {
            'periodKey': '2026-09',
            'predictedQuantity': 52,
            'lowerBound': 45,
            'upperBound': 59,
            'actualQuantity': null,
            'absolutePercentageError': null,
          },
        ],
        'generatedAt': Timestamp.fromDate(DateTime.utc(2026, 9, 2)),
        'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 9, 2)),
        'version': 1,
      }, id: 'company-1_collection_collection-1_2026-08');

      final entity = mapper.toEntity(dto);

      expect(entity.scopeType, DemandForecastScopeType.collection);
      expect(entity.status, DemandForecastStatus.forecast);
      expect(entity.isAvailable, isTrue);
      expect(entity.insufficientDataReason, isNull);
      expect(entity.history, hasLength(1));
      expect(entity.forecastPeriods, hasLength(1));
      expect(entity.forecastPeriods.first.predictedQuantity, 52);
      expect(entity.forecastPeriods.first.isEvaluated, isFalse);
    });

    test('maps an insufficientData payload with a parsed reason', () {
      final dto = DemandForecastDto.fromJson(<String, dynamic>{
        'organizationId': 'org-1',
        'companyId': 'company-1',
        'scopeType': 'region',
        'scopeId': 'SC',
        'scopeLabel': 'SC',
        'anchorMonthKey': '2026-08',
        'status': 'insufficientData',
        'insufficientDataReason': 'notEnoughHistory',
        'observedPeriodsCount': 3,
        'model': null,
        'modelVersion': null,
        'residualStdDev': null,
        'history': <Map<String, dynamic>>[],
        'forecastPeriods': <Map<String, dynamic>>[],
        'generatedAt': Timestamp.fromDate(DateTime.utc(2026, 9, 2)),
        'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 9, 2)),
        'version': 1,
      }, id: 'company-1_region_SC_2026-08');

      final entity = mapper.toEntity(dto);

      expect(entity.status, DemandForecastStatus.insufficientData);
      expect(entity.isAvailable, isFalse);
      expect(
        entity.insufficientDataReason,
        DemandForecastInsufficientDataReason.notEnoughHistory,
      );
      expect(entity.model, isNull);
      expect(entity.forecastPeriods, isEmpty);
    });

    test('maps an already-evaluated period with its actualQuantity', () {
      final dto = DemandForecastDto.fromJson(<String, dynamic>{
        'organizationId': 'org-1',
        'companyId': 'company-1',
        'scopeType': 'product',
        'scopeId': 'product-1',
        'scopeLabel': 'Camisa Polo',
        'anchorMonthKey': '2025-12',
        'status': 'forecast',
        'insufficientDataReason': null,
        'observedPeriodsCount': 12,
        'model': 'holtLinearTrend',
        'modelVersion': 'holt-linear-trend-v1',
        'residualStdDev': 3.0,
        'history': <Map<String, dynamic>>[],
        'forecastPeriods': <Map<String, dynamic>>[
          {
            'periodKey': '2026-01',
            'predictedQuantity': 100,
            'lowerBound': 80,
            'upperBound': 120,
            'actualQuantity': 90,
            'absolutePercentageError': 11.11,
          },
        ],
        'generatedAt': Timestamp.fromDate(DateTime.utc(2025, 12, 2)),
        'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 1, 5)),
        'version': 1,
      }, id: 'company-1_product_product-1_2025-12');

      final entity = mapper.toEntity(dto);

      expect(entity.forecastPeriods.first.isEvaluated, isTrue);
      expect(entity.forecastPeriods.first.actualQuantity, 90);
      expect(entity.forecastPeriods.first.absolutePercentageError, 11.11);
    });
  });
}
