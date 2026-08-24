import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../domain/entities/opportunity_outcome_reason.dart';
import '../../domain/value_objects/opportunity_outcome_type.dart';
import '../dtos/opportunity_outcome_reason_dto.dart';

@lazySingleton
final class OpportunityOutcomeReasonMapper {
  const OpportunityOutcomeReasonMapper();

  OpportunityOutcomeReason toEntity(OpportunityOutcomeReasonDto dto) {
    return OpportunityOutcomeReason(
      id: dto.id,
      organizationId: dto.organizationId,
      type: typeToEntity(dto.type),
      description: dto.description,
      isActive: dto.isActive,
      createdAt: dto.createdAt,
      createdBy: dto.createdBy,
      updatedAt: dto.updatedAt,
      updatedBy: dto.updatedBy,
      version: dto.version,
    );
  }

  OpportunityOutcomeReasonDto toDto(OpportunityOutcomeReason entity) {
    return OpportunityOutcomeReasonDto(
      id: entity.id,
      organizationId: entity.organizationId,
      type: typeToDto(entity.type),
      description: entity.description,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      createdBy: entity.createdBy,
      updatedAt: entity.updatedAt,
      updatedBy: entity.updatedBy,
      version: entity.version,
    );
  }

  OpportunityOutcomeType typeToEntity(String value) {
    return switch (value) {
      'won' => OpportunityOutcomeType.won,
      'lost' => OpportunityOutcomeType.lost,
      _ => throw ValidationException(
        'Invalid opportunity outcome type.',
        code: 'invalid_opportunity_outcome_type',
        cause: value,
      ),
    };
  }

  String typeToDto(OpportunityOutcomeType type) {
    return switch (type) {
      OpportunityOutcomeType.won => 'won',
      OpportunityOutcomeType.lost => 'lost',
    };
  }
}
