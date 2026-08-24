import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/opportunity.dart';
import '../repositories/opportunity_repository.dart';
import '../value_objects/opportunity_status.dart';
import '../value_objects/opportunity_sync_status.dart';
import 'opportunity_use_case_helpers.dart';

/// Marks an open Opportunity as won, always requiring [wonReason] so the
/// funnel keeps a traceable learning trail (a full configurable reason
/// catalog is left for TASK-061; a free-text reason is accepted here).
///
/// Terminal: once won, the Opportunity can never transition to any other
/// status through this or `MarkOpportunityLostUseCase` again.
final class MarkOpportunityWonUseCase {
  MarkOpportunityWonUseCase(this._repository);

  final OpportunityRepository _repository;

  Future<AppResult<Opportunity>> call({
    required String organizationId,
    required String id,
    required String wonReason,
    required String updatedBy,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedId = id.trim();
    final trimmedWonReason = wonReason.trim();
    final trimmedUpdatedBy = updatedBy.trim();
    final fieldErrors = <String, String>{};

    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedWonReason.isEmpty) {
      fieldErrors['wonReason'] = 'Won reason is required.';
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

    final now = DateTime.now().toUtc();
    final updated = opportunity.copyWith(
      status: OpportunityStatus.won,
      wonReason: trimmedWonReason,
      closedAt: now,
      updatedAt: now,
      updatedBy: trimmedUpdatedBy,
      version: opportunity.version + 1,
      syncStatus: OpportunitySyncStatus.pending,
    );

    return _repository.update(opportunity: updated);
  }
}
