import '../../../../core/utils/utils.dart';
import '../entities/pipeline_stage.dart';

/// Domain contract for [PipelineStage] persistence (TASK-058), decoupled
/// from Firestore/SharedPreferences.
abstract interface class PipelineStageRepository {
  Future<AppResult<PipelineStage>> create({required PipelineStage stage});

  Future<AppResult<PipelineStage>> update({required PipelineStage stage});

  Future<AppResult<List<PipelineStage>>> listByOrganization({
    required String organizationId,
  });

  /// Atomically re-assigns [PipelineStage.order] for every stage in
  /// [orderedStageIds] (0-based, matching list order) and returns the
  /// updated stages. [orderedStageIds] must already be validated by
  /// `ReorderPipelineStagesUseCase` to be exactly the organization's full
  /// stage id set — this method trusts that invariant rather than
  /// re-checking it.
  Future<AppResult<List<PipelineStage>>> reorder({
    required String organizationId,
    required List<String> orderedStageIds,
    required String updatedBy,
  });
}
