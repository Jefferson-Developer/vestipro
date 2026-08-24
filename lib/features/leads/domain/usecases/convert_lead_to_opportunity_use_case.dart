import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/lead.dart';
import '../repositories/lead_repository.dart';
import '../value_objects/lead_status.dart';
import '../value_objects/lead_sync_status.dart';
import 'lead_use_case_helpers.dart';

/// Converts a qualified Lead into an Opportunity, preserving traceability
/// through [Lead.convertedOpportunityId].
///
/// `Opportunity` itself is modeled in TASK-057 (`Opportunity.leadId`
/// mirrors `Customer.sourceLeadId`). This use case still accepts an
/// already-generated [opportunityId] from the caller instead of creating the
/// Opportunity aggregate directly, mirroring the split between
/// `CreateOpportunityUseCase` (creates the Opportunity, setting `leadId`)
/// and this use case (records the Lead-side link and status transition) —
/// the same two-step shape `ConvertLeadToCustomerUseCase` collapses into one
/// call because `Customer` creation doesn't depend on Lead-only inputs the
/// way `Opportunity.stageId`/`estimatedValue`/`probability` do. A future
/// orchestration use case may wrap both calls if the funnel UI (TASK-058)
/// needs a single entry point.
final class ConvertLeadToOpportunityUseCase {
  ConvertLeadToOpportunityUseCase(this._repository);

  final LeadRepository _repository;

  Future<AppResult<Lead>> call({
    required String organizationId,
    required String leadId,
    required String opportunityId,
    required String convertedBy,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedLeadId = leadId.trim();
    final trimmedOpportunityId = opportunityId.trim();
    final trimmedConvertedBy = convertedBy.trim();
    final fieldErrors = <String, String>{};

    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedLeadId.isEmpty) fieldErrors['leadId'] = 'LeadId is required.';
    if (trimmedOpportunityId.isEmpty) {
      fieldErrors['opportunityId'] = 'OpportunityId is required.';
    }
    if (trimmedConvertedBy.isEmpty) {
      fieldErrors['convertedBy'] = 'ConvertedBy is required.';
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure<Lead>(
        ValidationFailure(
          'Invalid lead conversion payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_lead_convert_payload',
        ),
      );
    }

    final leadResult = await _repository.getById(
      organizationId: trimmedOrganizationId,
      id: trimmedLeadId,
    );
    if (leadResult is AppFailure<Lead>) return leadResult;
    final lead = (leadResult as AppSuccess<Lead>).value;

    if (!lead.canTransitionTo(LeadStatus.converted)) {
      return AppFailure<Lead>(
        invalidLeadStatusTransitionFailure(
          from: lead.status,
          to: LeadStatus.converted,
        ),
      );
    }

    final now = DateTime.now().toUtc();
    final updated = lead.copyWith(
      status: LeadStatus.converted,
      convertedAt: now,
      convertedOpportunityId: trimmedOpportunityId,
      updatedAt: now,
      updatedBy: trimmedConvertedBy,
      version: lead.version + 1,
      syncStatus: LeadSyncStatus.pending,
    );

    return _repository.update(lead: updated);
  }
}
