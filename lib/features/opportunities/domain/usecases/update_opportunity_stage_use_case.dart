import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/opportunity.dart';
import '../repositories/opportunity_repository.dart';
import '../value_objects/opportunity_sync_status.dart';
import 'opportunity_use_case_helpers.dart';

/// Moves an Opportunity to a different pipeline stage (the configurable
/// funnel step from TASK-058), without touching its overall [OpportunityStatus].
///
/// Blocked once the Opportunity is won/lost: [Opportunity.canChangeStage]
/// only allows this while it is still open, per the rule that a closed
/// Opportunity must never change through a regular edit — only an explicit,
/// audited reopen flow (out of this task's scope) could allow it again.
final class UpdateOpportunityStageUseCase {
  UpdateOpportunityStageUseCase(this._repository);

  final OpportunityRepository _repository;

  Future<AppResult<Opportunity>> call({
    required String organizationId,
    required String id,
    required String stageId,
    required String updatedBy,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedId = id.trim();
    final trimmedStageId = stageId.trim();
    final trimmedUpdatedBy = updatedBy.trim();
    final fieldErrors = <String, String>{};

    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedStageId.isEmpty) {
      fieldErrors['stageId'] = 'StageId is required.';
    }
    if (trimmedUpdatedBy.isEmpty) {
      fieldErrors['updatedBy'] = 'UpdatedBy is required.';
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure<Opportunity>(
        ValidationFailure(
          'Invalid opportunity stage update payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_opportunity_stage_payload',
        ),
      );
    }

    final opportunityResult = await _repository.getById(
      organizationId: trimmedOrganizationId,
      id: trimmedId,
    );
    if (opportunityResult is AppFailure<Opportunity>) return opportunityResult;
    final opportunity = (opportunityResult as AppSuccess<Opportunity>).value;

    if (!opportunity.canChangeStage) {
      return AppFailure<Opportunity>(
        opportunityStageChangeBlockedFailure(status: opportunity.status),
      );
    }

    final now = DateTime.now().toUtc();
    final updated = opportunity.copyWith(
      stageId: trimmedStageId,
      updatedAt: now,
      updatedBy: trimmedUpdatedBy,
      version: opportunity.version + 1,
      syncStatus: OpportunitySyncStatus.pending,
    );

    return _repository.update(opportunity: updated);
  }
}
