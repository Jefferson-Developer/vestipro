import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/pipeline_stage.dart';
import '../repositories/pipeline_stage_repository.dart';
import 'pipeline_stage_use_case_helpers.dart';

/// Re-orders every [PipelineStage] of an organization (TASK-058), used by
/// the admin screen's drag-to-reorder list.
///
/// [orderedStageIds] must contain exactly the organization's current stage
/// ids, once each, in the caller's desired final order — a partial list, a
/// duplicate or an unknown id is rejected rather than guessed at, so a
/// stale client never silently drops a stage from the funnel.
///
/// Administrative action, same RBAC note as `CreatePipelineStageUseCase`.
@injectable
final class ReorderPipelineStagesUseCase {
  ReorderPipelineStagesUseCase(this._repository);

  final PipelineStageRepository _repository;

  Future<AppResult<List<PipelineStage>>> call({
    required String organizationId,
    required List<String> orderedStageIds,
    required String updatedBy,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedUpdatedBy = updatedBy.trim();
    final fieldErrors = <String, String>{};

    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (orderedStageIds.isEmpty) {
      fieldErrors['orderedStageIds'] = 'OrderedStageIds is required.';
    }
    if (trimmedUpdatedBy.isEmpty) {
      fieldErrors['updatedBy'] = 'UpdatedBy is required.';
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure<List<PipelineStage>>(
        ValidationFailure(
          'Invalid pipeline stage reorder payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_pipeline_stage_reorder_payload',
        ),
      );
    }

    final existingResult = await _repository.listByOrganization(
      organizationId: trimmedOrganizationId,
    );
    if (existingResult is AppFailure<List<PipelineStage>>) {
      return existingResult;
    }
    final existingStages =
        (existingResult as AppSuccess<List<PipelineStage>>).value;

    final requestedIds = orderedStageIds.map((id) => id.trim()).toList();
    final existingIds = existingStages.map((stage) => stage.id).toSet();
    final isSameSet =
        requestedIds.length == existingIds.length &&
        requestedIds.toSet().length == requestedIds.length &&
        existingIds.containsAll(requestedIds);
    if (!isSameSet) {
      return AppFailure<List<PipelineStage>>(
        invalidPipelineStageReorderSetFailure(),
      );
    }

    return _repository.reorder(
      organizationId: trimmedOrganizationId,
      orderedStageIds: requestedIds,
      updatedBy: trimmedUpdatedBy,
    );
  }
}
