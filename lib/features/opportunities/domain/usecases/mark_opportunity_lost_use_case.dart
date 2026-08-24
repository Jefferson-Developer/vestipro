import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/opportunity.dart';
import '../repositories/opportunity_repository.dart';
import '../value_objects/opportunity_status.dart';
import '../value_objects/opportunity_sync_status.dart';
import 'opportunity_use_case_helpers.dart';

/// Marks an open Opportunity as lost, always requiring [lostReason] so the
/// funnel keeps a traceable learning trail (a full configurable reason
/// catalog is left for TASK-061; a free-text reason is accepted here).
///
/// [stageId], when provided, also moves the Opportunity onto that pipeline
/// stage in the same update — see `MarkOpportunityWonUseCase` docs for why
/// (TASK-058).
///
/// Terminal: once lost, the Opportunity can never transition to any other
/// status through this or `MarkOpportunityWonUseCase` again.
@injectable
final class MarkOpportunityLostUseCase {
  MarkOpportunityLostUseCase(this._repository);

  final OpportunityRepository _repository;

  Future<AppResult<Opportunity>> call({
    required String organizationId,
    required String id,
    required String lostReason,
    required String updatedBy,
    String? stageId,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedId = id.trim();
    final trimmedLostReason = lostReason.trim();
    final trimmedUpdatedBy = updatedBy.trim();
    final normalizedStageId = normalizeOpportunityOptional(stageId);
    final fieldErrors = <String, String>{};

    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedLostReason.isEmpty) {
      fieldErrors['lostReason'] = 'Lost reason is required.';
    }
    if (trimmedUpdatedBy.isEmpty) {
      fieldErrors['updatedBy'] = 'UpdatedBy is required.';
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure<Opportunity>(
        ValidationFailure(
          'Invalid opportunity lost payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_opportunity_lost_payload',
        ),
      );
    }

    final opportunityResult = await _repository.getById(
      organizationId: trimmedOrganizationId,
      id: trimmedId,
    );
    if (opportunityResult is AppFailure<Opportunity>) return opportunityResult;
    final opportunity = (opportunityResult as AppSuccess<Opportunity>).value;

    if (!opportunity.canTransitionStatusTo(OpportunityStatus.lost)) {
      return AppFailure<Opportunity>(
        invalidOpportunityStatusTransitionFailure(
          from: opportunity.status,
          to: OpportunityStatus.lost,
        ),
      );
    }

    final now = DateTime.now().toUtc();
    final updated = opportunity.copyWith(
      stageId: normalizedStageId ?? opportunity.stageId,
      status: OpportunityStatus.lost,
      lostReason: trimmedLostReason,
      closedAt: now,
      updatedAt: now,
      updatedBy: trimmedUpdatedBy,
      version: opportunity.version + 1,
      syncStatus: OpportunitySyncStatus.pending,
    );

    return _repository.update(opportunity: updated);
  }
}
