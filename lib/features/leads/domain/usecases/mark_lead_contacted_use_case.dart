import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/lead.dart';
import '../repositories/lead_repository.dart';
import '../value_objects/lead_status.dart';
import '../value_objects/lead_sync_status.dart';
import 'lead_use_case_helpers.dart';

/// Moves a Lead from `newLead` to `contacted` once the sales rep makes the
/// first contact attempt, opening the door to qualification/disqualification.
final class MarkLeadContactedUseCase {
  MarkLeadContactedUseCase(this._repository);

  final LeadRepository _repository;

  Future<AppResult<Lead>> call({
    required String organizationId,
    required String id,
    required String updatedBy,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedId = id.trim();
    final trimmedUpdatedBy = updatedBy.trim();
    final fieldErrors = <String, String>{};

    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedUpdatedBy.isEmpty) {
      fieldErrors['updatedBy'] = 'UpdatedBy is required.';
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure<Lead>(
        ValidationFailure(
          'Invalid lead contact payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_lead_contact_payload',
        ),
      );
    }

    final leadResult = await _repository.getById(
      organizationId: trimmedOrganizationId,
      id: trimmedId,
    );
    if (leadResult is AppFailure<Lead>) return leadResult;
    final lead = (leadResult as AppSuccess<Lead>).value;

    if (!lead.canTransitionTo(LeadStatus.contacted)) {
      return AppFailure<Lead>(
        invalidLeadStatusTransitionFailure(
          from: lead.status,
          to: LeadStatus.contacted,
        ),
      );
    }

    final now = DateTime.now().toUtc();
    final updated = lead.copyWith(
      status: LeadStatus.contacted,
      contactedAt: now,
      updatedAt: now,
      updatedBy: trimmedUpdatedBy,
      version: lead.version + 1,
      syncStatus: LeadSyncStatus.pending,
    );

    return _repository.update(lead: updated);
  }
}
