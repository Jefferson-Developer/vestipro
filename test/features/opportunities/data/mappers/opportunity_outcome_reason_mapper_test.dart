import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/opportunities/data/dtos/opportunity_outcome_reason_dto.dart';
import 'package:vestipro/features/opportunities/data/mappers/opportunity_outcome_reason_mapper.dart';
import 'package:vestipro/features/opportunities/opportunities.dart';

void main() {
  group('OpportunityOutcomeReasonMapper', () {
    const mapper = OpportunityOutcomeReasonMapper();

    test('maps every field to entity and back', () {
      final dto = OpportunityOutcomeReasonDto(
        id: 'reason-1',
        organizationId: 'org-1',
        type: 'lost',
        description: 'Concorrente com preco menor',
        isActive: false,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'admin-1',
        updatedAt: DateTime.utc(2026, 1, 2),
        updatedBy: 'admin-2',
        version: 3,
      );

      final entity = mapper.toEntity(dto);
      final roundTripped = mapper.toDto(entity);

      expect(entity.type, OpportunityOutcomeType.lost);
      expect(entity.isActive, isFalse);
      expect(roundTripped.type, 'lost');
      expect(roundTripped.description, dto.description);
      expect(roundTripped.version, 3);
    });

    test('throws for an unknown outcome type', () {
      expect(
        () => mapper.typeToEntity('draw'),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
