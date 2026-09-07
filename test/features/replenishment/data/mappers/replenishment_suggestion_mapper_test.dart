import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/replenishment/replenishment.dart';

void main() {
  group('ReplenishmentSuggestionMapper', () {
    const mapper = ReplenishmentSuggestionMapper();

    test(
      'maps a decided DTO to the entity, parsing every enum/value object',
      () {
        final decidedAt = DateTime.utc(2026, 9, 8);
        final dto = ReplenishmentSuggestionDto(
          id: 'warehouse-1_variant-1_2026-09-07',
          organizationId: 'org-1',
          companyId: 'company-1',
          warehouseId: 'warehouse-1',
          variantId: 'variant-1',
          productId: 'product-1',
          periodStart: '2026-06-15',
          periodEnd: '2026-09-07',
          status: 'adjusted',
          suggestedQuantity: 80,
          targetStockQuantity: 100,
          finalQuantity: 50,
          currentSellableQuantity: 20,
          futureStockQuantity: 0,
          coverageTargetDays: 30,
          safetyStockQuantity: 10,
          seasonalityFactor: 1,
          decisionAudit: <ReplenishmentDecisionAuditEntryDto>[
            ReplenishmentDecisionAuditEntryDto(
              action: 'adjust',
              actorId: 'manager-1',
              actorName: 'Gestor Um',
              at: decidedAt,
              note: 'Ajustado por sazonalidade.',
            ),
          ],
          generatedAt: DateTime.utc(2026, 9, 7),
          updatedAt: decidedAt,
          version: 1,
          turnoverEvidence: const ReplenishmentTurnoverEvidenceDto(
            averageDailySalesQuantity: 5,
            stockCoverageDays: 4,
            turnoverRate: 0.5,
            coverageStatus: 'ready',
          ),
          decidedBy: 'manager-1',
          decidedByName: 'Gestor Um',
          decidedAt: decidedAt,
        );

        final entity = mapper.toEntity(dto);

        expect(entity.status, ReplenishmentSuggestionStatus.adjusted);
        expect(entity.isDecided, isTrue);
        expect(entity.finalQuantity, 50);
        expect(entity.turnoverEvidence, isNotNull);
        expect(entity.decisionAudit, hasLength(1));
        expect(
          entity.decisionAudit.single.action,
          ReplenishmentDecisionAction.adjust,
        );
        expect(entity.decisionAudit.single.note, 'Ajustado por sazonalidade.');
      },
    );

    test('maps an insufficientData DTO with a null turnoverEvidence', () {
      final dto = ReplenishmentSuggestionDto(
        id: 'warehouse-1_variant-2_2026-09-07',
        organizationId: 'org-1',
        companyId: 'company-1',
        warehouseId: 'warehouse-1',
        variantId: 'variant-2',
        productId: 'product-2',
        periodStart: '2026-06-15',
        periodEnd: '2026-09-07',
        status: 'insufficientData',
        insufficientDataReason: 'noTurnoverHistory',
        suggestedQuantity: 0,
        targetStockQuantity: 0,
        currentSellableQuantity: 0,
        futureStockQuantity: 0,
        coverageTargetDays: 30,
        safetyStockQuantity: 0,
        seasonalityFactor: 1,
        decisionAudit: const <ReplenishmentDecisionAuditEntryDto>[],
        generatedAt: DateTime.utc(2026, 9, 7),
        updatedAt: DateTime.utc(2026, 9, 7),
        version: 1,
      );

      final entity = mapper.toEntity(dto);

      expect(entity.status, ReplenishmentSuggestionStatus.insufficientData);
      expect(entity.isDecided, isFalse);
      expect(entity.insufficientDataReason, 'noTurnoverHistory');
      expect(entity.turnoverEvidence, isNull);
      expect(entity.finalQuantity, isNull);
    });
  });
}
