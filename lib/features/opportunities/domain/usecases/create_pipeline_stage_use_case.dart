import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/pipeline_stage.dart';
import '../repositories/pipeline_stage_repository.dart';
import '../value_objects/pipeline_stage_terminal_type.dart';
import 'pipeline_stage_use_case_helpers.dart';

/// Creates a [PipelineStage] (TASK-058), appending it at the end of the
/// organization's current stage order.
///
/// This is an administrative action: gated in the UI by
/// `Capability.pipelineStageManage` (restricted to
/// OWNER/ADMIN/SALES_MANAGER, see `RolePermissionMatrix`), re-validated here
/// only for data integrity, never for authorization — the same
/// "UI only shows/enables" contract every other VestiPro use case follows.
@injectable
final class CreatePipelineStageUseCase {
  CreatePipelineStageUseCase(this._repository);

  final PipelineStageRepository _repository;

  Future<AppResult<PipelineStage>> call({
    required String id,
    required String organizationId,
    required String name,
    required String colorHex,
    PipelineStageTerminalType terminalType = PipelineStageTerminalType.none,
    required String createdBy,
  }) async {
    final trimmedId = id.trim();
    final trimmedOrganizationId = organizationId.trim();
    final trimmedName = name.trim();
    final trimmedColorHex = colorHex.trim();
    final trimmedCreatedBy = createdBy.trim();
    final fieldErrors = <String, String>{};

    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedName.isEmpty) fieldErrors['name'] = 'Name is required.';
    if (!isValidPipelineStageColor(trimmedColorHex)) {
      fieldErrors['colorHex'] = 'ColorHex must be a "#RRGGBB" value.';
    }
    if (trimmedCreatedBy.isEmpty) {
      fieldErrors['createdBy'] = 'CreatedBy is required.';
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure<PipelineStage>(
        ValidationFailure(
          'Invalid pipeline stage creation payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_pipeline_stage_create_payload',
        ),
      );
    }

    final existingResult = await _repository.listByOrganization(
      organizationId: trimmedOrganizationId,
    );
    if (existingResult is AppFailure<List<PipelineStage>>) {
      return AppFailure<PipelineStage>(existingResult.failure);
    }
    final existingStages =
        (existingResult as AppSuccess<List<PipelineStage>>).value;

    if (terminalType != PipelineStageTerminalType.none &&
        existingStages.any((stage) => stage.terminalType == terminalType)) {
      return AppFailure<PipelineStage>(
        duplicateTerminalPipelineStageFailure(terminalType: terminalType),
      );
    }

    final now = DateTime.now().toUtc();
    final stage = PipelineStage(
      id: trimmedId,
      organizationId: trimmedOrganizationId,
      name: trimmedName,
      order: existingStages.length,
      colorHex: trimmedColorHex,
      terminalType: terminalType,
      createdAt: now,
      createdBy: trimmedCreatedBy,
      updatedAt: now,
      updatedBy: trimmedCreatedBy,
      version: 1,
    );

    return _repository.create(stage: stage);
  }
}
