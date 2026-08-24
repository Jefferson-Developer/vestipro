import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/opportunity.dart';
import '../entities/opportunity_outcome_reason.dart';
import '../repositories/opportunity_outcome_reason_repository.dart';
import '../repositories/opportunity_repository.dart';
import '../value_objects/opportunity_outcome_type.dart';
import '../value_objects/opportunity_status.dart';
import '../value_objects/opportunity_sync_status.dart';
import 'opportunity_outcome_reason_use_case_helpers.dart';
import 'opportunity_use_case_helpers.dart';

/// Marks an open Opportunity as won, always requiring an active won
/// [reasonId] from the organization's configurable catalog (TASK-061).
///
/// [stageId], when provided, also moves the Opportunity onto that pipeline
/// stage in the same update (TASK-058: `SalesPipelineBloc` passes the
/// terminal "won" stage's id here when the funnel closes an Opportunity by
/// dropping it on that column, so the board and the status stay in sync in
/// one write). Omitting it leaves `stageId` unchanged, e.g. for a future
/// "mark won" action outside the pipeline board.
///
/// Terminal: once won, the Opportunity can never transition to any other
/// status through this or `MarkOpportunityLostUseCase` again.
@injectable
final class MarkOpportunityWonUseCase {
  MarkOpportunityWonUseCase(this._repository, this._reasonRepository);

  final OpportunityRepository _repository;
  final OpportunityOutcomeReasonRepository _reasonRepository;

  Future<AppResult<Opportunity>> call({
    required String organizationId,
    required String id,
    required String reasonId,
    String? note,
    required String updatedBy,
    String? stageId,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedId = id.trim();
    final trimmedReasonId = reasonId.trim();
    final normalizedNote = normalizeOutcomeNote(note);
    final trimmedUpdatedBy = updatedBy.trim();
    final normalizedStageId = normalizeOpportunityOptional(stageId);
    final fieldErrors = <String, String>{};

    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedReasonId.isEmpty) {
      fieldErrors['reasonId'] = 'ReasonId is required.';
    }
    if (trimmedUpdatedBy.isEmpty) {
      fieldErrors['updatedBy'] = 'UpdatedBy is required.';
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure<Opportunity>(
        ValidationFailure(
          'Invalid opportunity won payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_opportunity_won_payload',
        ),
      );
    }

    final opportunityResult = await _repository.getById(
      organizationId: trimmedOrganizationId,
      id: trimmedId,
    );
    if (opportunityResult is AppFailure<Opportunity>) return opportunityResult;
    final opportunity = (opportunityResult as AppSuccess<Opportunity>).value;

    if (!opportunity.canTransitionStatusTo(OpportunityStatus.won)) {
      return AppFailure<Opportunity>(
        invalidOpportunityStatusTransitionFailure(
          from: opportunity.status,
          to: OpportunityStatus.won,
        ),
      );
    }

    final reasonResult = await loadSelectableOutcomeReason(
      repository: _reasonRepository,
      organizationId: trimmedOrganizationId,
      reasonId: trimmedReasonId,
      expectedType: OpportunityOutcomeType.won,
    );
    if (reasonResult is AppFailure<OpportunityOutcomeReason>) {
      return AppFailure<Opportunity>(reasonResult.failure);
    }
    final reason = (reasonResult as AppSuccess<OpportunityOutcomeReason>).value;

    final now = DateTime.now().toUtc();
    final updated = opportunity.copyWith(
      stageId: normalizedStageId ?? opportunity.stageId,
      status: OpportunityStatus.won,
      wonReasonId: trimmedReasonId,
      wonReason: snapshotForOutcomeReason(reason),
      wonReasonNote: normalizedNote,
      closedAt: now,
      updatedAt: now,
      updatedBy: trimmedUpdatedBy,
      version: opportunity.version + 1,
      syncStatus: OpportunitySyncStatus.pending,
    );

    return _repository.update(opportunity: updated);
  }
}
