import 'package:collection/collection.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/pipeline_stage.dart';
import '../repositories/pipeline_stage_repository.dart';
import 'pipeline_stage_use_case_helpers.dart';

/// Renames a [PipelineStage] and/or updates its color indicator
/// (TASK-058). [PipelineStage.terminalType] and [PipelineStage.order] are
/// never touched here — see the class docs on [PipelineStage] for why
/// `terminalType` is immutable, and `ReorderPipelineStagesUseCase` for
/// `order`.
///
/// Administrative action, same RBAC note as `CreatePipelineStageUseCase`.
@injectable
final class RenamePipelineStageUseCase {
  RenamePipelineStageUseCase(this._repository);

  final PipelineStageRepository _repository;

  Future<AppResult<PipelineStage>> call({
    required String organizationId,
    required String id,
    required String name,
    required String colorHex,
    required String updatedBy,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedId = id.trim();
    final trimmedName = name.trim();
    final trimmedColorHex = colorHex.trim();
    final trimmedUpdatedBy = updatedBy.trim();
    final fieldErrors = <String, String>{};

    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedName.isEmpty) fieldErrors['name'] = 'Name is required.';
    if (!isValidPipelineStageColor(trimmedColorHex)) {
      fieldErrors['colorHex'] = 'ColorHex must be a "#RRGGBB" value.';
    }
    if (trimmedUpdatedBy.isEmpty) {
      fieldErrors['updatedBy'] = 'UpdatedBy is required.';
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure<PipelineStage>(
        ValidationFailure(
          'Invalid pipeline stage rename payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_pipeline_stage_rename_payload',
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
    final current = existingStages.firstWhereOrNull(
      (stage) => stage.id == trimmedId,
    );

    if (current == null) {
      return const AppFailure<PipelineStage>(
        NotFoundFailure(
          'Pipeline stage not found.',
          code: 'pipeline_stage_not_found',
        ),
      );
    }

    return _repository.update(
      stage: current.copyWith(
        name: trimmedName,
        colorHex: trimmedColorHex,
        updatedAt: DateTime.now().toUtc(),
        updatedBy: trimmedUpdatedBy,
        version: current.version + 1,
      ),
    );
  }
}
