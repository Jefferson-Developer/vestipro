import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../domain/entities/pipeline_stage.dart';
import '../../domain/value_objects/pipeline_stage_terminal_type.dart';
import '../dtos/pipeline_stage_dto.dart';

@lazySingleton
final class PipelineStageMapper {
  const PipelineStageMapper();

  PipelineStage toEntity(PipelineStageDto dto) {
    return PipelineStage(
      id: dto.id,
      organizationId: dto.organizationId,
      name: dto.name,
      order: dto.order,
      colorHex: dto.colorHex,
      terminalType: terminalTypeToEntity(dto.terminalType),
      createdAt: dto.createdAt,
      createdBy: dto.createdBy,
      updatedAt: dto.updatedAt,
      updatedBy: dto.updatedBy,
      version: dto.version,
    );
  }

  PipelineStageDto toDto(PipelineStage entity) {
    return PipelineStageDto(
      id: entity.id,
      organizationId: entity.organizationId,
      name: entity.name,
      order: entity.order,
      colorHex: entity.colorHex,
      terminalType: terminalTypeToDto(entity.terminalType),
      createdAt: entity.createdAt,
      createdBy: entity.createdBy,
      updatedAt: entity.updatedAt,
      updatedBy: entity.updatedBy,
      version: entity.version,
    );
  }

  PipelineStageTerminalType terminalTypeToEntity(String value) {
    return switch (value) {
      'none' => PipelineStageTerminalType.none,
      'won' => PipelineStageTerminalType.won,
      'lost' => PipelineStageTerminalType.lost,
      _ => throw ValidationException(
        'Invalid pipeline stage terminal type.',
        code: 'invalid_pipeline_stage_terminal_type',
        cause: value,
      ),
    };
  }

  String terminalTypeToDto(PipelineStageTerminalType terminalType) {
    return switch (terminalType) {
      PipelineStageTerminalType.none => 'none',
      PipelineStageTerminalType.won => 'won',
      PipelineStageTerminalType.lost => 'lost',
    };
  }
}
