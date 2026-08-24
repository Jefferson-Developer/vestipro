import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/lead.dart';
import '../repositories/lead_repository.dart';
import '../value_objects/lead_status.dart';
import '../value_objects/lead_sync_status.dart';
import 'lead_use_case_helpers.dart';

/// Disqualifies a Lead, always requiring a reason so the funnel keeps a
/// traceable learning trail (a full configurable reason catalog is left for
/// TASK-061; a free-text reason is accepted here).
final class DisqualifyLeadUseCase {
  DisqualifyLeadUseCase(this._repository);

  final LeadRepository _repository;

  Future<AppResult<Lead>> call({
    required String organizationId,
    required String id,
    required String reason,
    required String updatedBy,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedId = id.trim();
    final trimmedReason = reason.trim();
    final trimmedUpdatedBy = updatedBy.trim();
    final fieldErrors = <String, String>{};

    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedReason.isEmpty) {
      fieldErrors['reason'] = 'Disqualification reason is required.';
    }
    if (trimmedUpdatedBy.isEmpty) {
      fieldErrors['updatedBy'] = 'UpdatedBy is required.';
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure<Lead>(
        ValidationFailure(
          'Invalid lead disqualification payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_lead_disqualify_payload',
        ),
      );
    }

    final leadResult = await _repository.getById(
      organizationId: trimmedOrganizationId,
      id: trimmedId,
    );
    if (leadResult is AppFailure<Lead>) return leadResult;
    final lead = (leadResult as AppSuccess<Lead>).value;

    if (!lead.canTransitionTo(LeadStatus.disqualified)) {
      return AppFailure<Lead>(
        invalidLeadStatusTransitionFailure(
          from: lead.status,
          to: LeadStatus.disqualified,
        ),
      );
    }

    final now = DateTime.now().toUtc();
    final updated = lead.copyWith(
      status: LeadStatus.disqualified,
      disqualificationReason: trimmedReason,
      updatedAt: now,
      updatedBy: trimmedUpdatedBy,
      version: lead.version + 1,
      syncStatus: LeadSyncStatus.pending,
    );

    return _repository.update(lead: updated);
  }
}
