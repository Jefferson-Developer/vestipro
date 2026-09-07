import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/demand_forecast/demand_forecast.dart';

Map<String, dynamic> _validJson({List<dynamic>? forecastPeriods}) {
  return <String, dynamic>{
    'organizationId': 'org-1',
    'companyId': 'company-1',
    'scopeType': 'product',
    'scopeId': 'product-1',
    'scopeLabel': 'Camisa Polo',
    'anchorMonthKey': '2026-08',
    'status': 'forecast',
    'insufficientDataReason': null,
    'observedPeriodsCount': 12,
    'model': 'holtLinearTrend',
    'modelVersion': 'holt-linear-trend-v1',
    'residualStdDev': 2.5,
    'history': <Map<String, dynamic>>[
      {'periodKey': '2026-07', 'quantity': 30, 'observed': true},
      {'periodKey': '2026-08', 'quantity': 32, 'observed': true},
    ],
    'forecastPeriods':
        forecastPeriods ??
        <Map<String, dynamic>>[
          {
            'periodKey': '2026-09',
            'predictedQuantity': 34,
            'lowerBound': 28,
            'upperBound': 40,
            'actualQuantity': null,
            'absolutePercentageError': null,
          },
        ],
    'generatedAt': Timestamp.fromDate(DateTime.utc(2026, 9, 2)),
    'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 9, 2)),
    'version': 1,
  };
}

void main() {
  group('DemandForecastDto.fromJson', () {
    test('parses a valid forecast payload', () {
      final dto = DemandForecastDto.fromJson(_validJson(), id: 'doc-1');

      expect(dto.id, 'doc-1');
      expect(dto.scopeType, 'product');
      expect(dto.status, 'forecast');
      expect(dto.observedPeriodsCount, 12);
      expect(dto.history, hasLength(2));
      expect(dto.forecastPeriods, hasLength(1));
      expect(dto.forecastPeriods.first.predictedQuantity, 34);
      expect(dto.forecastPeriods.first.actualQuantity, isNull);
    });

    test(
      'parses an insufficientData payload with an empty forecastPeriods list',
      () {
        final json = _validJson(forecastPeriods: const <Map<String, dynamic>>[])
          ..['status'] = 'insufficientData'
          ..['insufficientDataReason'] = 'notEnoughHistory'
          ..['model'] = null
          ..['modelVersion'] = null
          ..['residualStdDev'] = null;

        final dto = DemandForecastDto.fromJson(json, id: 'doc-2');

        expect(dto.status, 'insufficientData');
        expect(dto.insufficientDataReason, 'notEnoughHistory');
        expect(dto.model, isNull);
        expect(dto.forecastPeriods, isEmpty);
      },
    );

    test('parses a period already evaluated with a real actualQuantity', () {
      final json = _validJson(
        forecastPeriods: <Map<String, dynamic>>[
          {
            'periodKey': '2026-09',
            'predictedQuantity': 34,
            'lowerBound': 28,
            'upperBound': 40,
            'actualQuantity': 30,
            'absolutePercentageError': 11.76,
          },
        ],
      );

      final dto = DemandForecastDto.fromJson(json, id: 'doc-3');

      expect(dto.forecastPeriods.first.actualQuantity, 30);
      expect(dto.forecastPeriods.first.absolutePercentageError, 11.76);
    });

    test('throws ValidationException for a missing required field', () {
      final json = _validJson()..remove('scopeLabel');
      expect(
        () => DemandForecastDto.fromJson(json, id: 'doc-1'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('throws ValidationException for a malformed history entry', () {
      final json = _validJson()
        ..['history'] = <Map<String, dynamic>>[
          {
            'periodKey': '2026-07',
            'quantity': 'not-a-number',
            'observed': true,
          },
        ];
      expect(
        () => DemandForecastDto.fromJson(json, id: 'doc-1'),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('DemandForecastDto.toJson', () {
    test('round-trips through fromJson/toJson', () {
      final original = DemandForecastDto.fromJson(_validJson(), id: 'doc-1');
      final roundTripped = DemandForecastDto.fromJson(
        original.toJson(),
        id: 'doc-1',
      );

      expect(roundTripped.scopeId, original.scopeId);
      expect(roundTripped.status, original.status);
      expect(
        roundTripped.forecastPeriods.first.predictedQuantity,
        original.forecastPeriods.first.predictedQuantity,
      );
    });
  });
}
