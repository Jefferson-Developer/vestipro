import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/pipeline_stage.dart';
import '../repositories/pipeline_stage_repository.dart';

/// Lists an organization's [PipelineStage]s (TASK-058), sorted by
/// [PipelineStage.order], for both the pipeline board and the stage admin
/// screen.
@injectable
final class ListPipelineStagesUseCase {
  const ListPipelineStagesUseCase(this._repository);

  final PipelineStageRepository _repository;

  Future<AppResult<List<PipelineStage>>> call({
    required String organizationId,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    if (trimmedOrganizationId.isEmpty) {
      return const AppFailure<List<PipelineStage>>(
        ValidationFailure(
          'Invalid pipeline stage listing payload.',
          fieldErrors: <String, String>{
            'organizationId': 'OrganizationId is required.',
          },
          code: 'invalid_pipeline_stage_list_payload',
        ),
      );
    }

    final result = await _repository.listByOrganization(
      organizationId: trimmedOrganizationId,
    );
    return result.fold(
      onSuccess: (stages) {
        final sorted = List<PipelineStage>.of(stages)
          ..sort((a, b) => a.order.compareTo(b.order));
        return AppSuccess<List<PipelineStage>>(sorted);
      },
      onFailure: AppFailure<List<PipelineStage>>.new,
    );
  }
}
