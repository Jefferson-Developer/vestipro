import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/replenishment/replenishment.dart';

Map<String, dynamic> _validPayload({Map<String, dynamic>? overrides}) {
  final now = Timestamp.fromDate(DateTime.utc(2026, 9, 7));
  return <String, dynamic>{
    'organizationId': 'org-1',
    'companyId': 'company-1',
    'warehouseId': 'warehouse-1',
    'variantId': 'variant-1',
    'productId': 'product-1',
    'periodStart': '2026-06-15',
    'periodEnd': '2026-09-07',
    'status': 'suggested',
    'insufficientDataReason': null,
    'suggestedQuantity': 80,
    'targetStockQuantity': 100,
    'finalQuantity': null,
    'currentSellableQuantity': 20,
    'futureStockQuantity': 0,
    'turnoverEvidence': <String, dynamic>{
      'averageDailySalesQuantity': 5.0,
      'stockCoverageDays': 4.0,
      'turnoverRate': 0.5,
      'coverageStatus': 'ready',
    },
    'parametersSnapshot': <String, dynamic>{
      'coverageTargetDays': 30,
      'safetyStockQuantity': 10,
      'seasonalityFactor': 1.0,
    },
    'decidedBy': null,
    'decidedByName': null,
    'decidedAt': null,
    'decisionAudit': <dynamic>[],
    'generatedAt': now,
    'updatedAt': now,
    'version': 1,
    ...?overrides,
  };
}

void main() {
  group('ReplenishmentSuggestionDto.fromJson', () {
    test('parses a valid, undecided payload', () {
      final dto = ReplenishmentSuggestionDto.fromJson(
        _validPayload(),
        id: 'warehouse-1_variant-1_2026-09-07',
      );

      expect(dto.id, 'warehouse-1_variant-1_2026-09-07');
      expect(dto.status, 'suggested');
      expect(dto.suggestedQuantity, 80);
      expect(dto.finalQuantity, isNull);
      expect(dto.turnoverEvidence?.averageDailySalesQuantity, 5.0);
      expect(dto.coverageTargetDays, 30);
      expect(dto.decisionAudit, isEmpty);
    });

    test('parses a decided payload with a populated decisionAudit', () {
      final decidedAt = Timestamp.fromDate(DateTime.utc(2026, 9, 8));
      final dto = ReplenishmentSuggestionDto.fromJson(
        _validPayload(
          overrides: <String, dynamic>{
            'status': 'accepted',
            'finalQuantity': 80,
            'decidedBy': 'manager-1',
            'decidedByName': 'Gestor Um',
            'decidedAt': decidedAt,
            'decisionAudit': <dynamic>[
              <String, dynamic>{
                'action': 'accept',
                'actorId': 'manager-1',
                'actorName': 'Gestor Um',
                'at': decidedAt,
                'note': null,
              },
            ],
          },
        ),
        id: 'warehouse-1_variant-1_2026-09-07',
      );

      expect(dto.status, 'accepted');
      expect(dto.finalQuantity, 80);
      expect(dto.decidedByName, 'Gestor Um');
      expect(dto.decisionAudit, hasLength(1));
      expect(dto.decisionAudit.single.action, 'accept');
    });

    test('parses insufficientData payload with a null turnoverEvidence', () {
      final dto = ReplenishmentSuggestionDto.fromJson(
        _validPayload(
          overrides: <String, dynamic>{
            'status': 'insufficientData',
            'insufficientDataReason': 'noTurnoverHistory',
            'suggestedQuantity': 0,
            'targetStockQuantity': 0,
            'turnoverEvidence': null,
          },
        ),
        id: 'warehouse-1_variant-2_2026-09-07',
      );

      expect(dto.status, 'insufficientData');
      expect(dto.insufficientDataReason, 'noTurnoverHistory');
      expect(dto.turnoverEvidence, isNull);
    });

    test('throws ValidationException for a missing required field', () {
      final payload = _validPayload()..remove('warehouseId');
      expect(
        () => ReplenishmentSuggestionDto.fromJson(payload, id: 'doc-1'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('throws ValidationException for a malformed parametersSnapshot', () {
      final dto = _validPayload(
        overrides: <String, dynamic>{
          'parametersSnapshot': <String, dynamic>{
            'coverageTargetDays': 'not-a-number',
            'safetyStockQuantity': 10,
            'seasonalityFactor': 1.0,
          },
        },
      );
      expect(
        () => ReplenishmentSuggestionDto.fromJson(dto, id: 'doc-1'),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('ReplenishmentSuggestionDto round-trip', () {
    test('toJson feeds back into fromJson without losing data', () {
      final original = ReplenishmentSuggestionDto.fromJson(
        _validPayload(),
        id: 'warehouse-1_variant-1_2026-09-07',
      );

      final roundTripped = ReplenishmentSuggestionDto.fromJson(
        original.toJson(),
        id: original.id,
      );

      expect(roundTripped.status, original.status);
      expect(roundTripped.suggestedQuantity, original.suggestedQuantity);
      expect(
        roundTripped.turnoverEvidence?.averageDailySalesQuantity,
        original.turnoverEvidence?.averageDailySalesQuantity,
      );
    });
  });
}
