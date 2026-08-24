import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/lead.dart';
import '../repositories/lead_repository.dart';
import '../value_objects/lead_status.dart';
import '../value_objects/lead_sync_status.dart';
import 'lead_use_case_helpers.dart';

/// Qualifies a Lead that has already been contacted, opening the door to
/// `ConvertLeadToCustomerUseCase`/`ConvertLeadToOpportunityUseCase`.
@injectable
final class QualifyLeadUseCase {
  QualifyLeadUseCase(this._repository);

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
          'Invalid lead qualification payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_lead_qualify_payload',
        ),
      );
    }

    final leadResult = await _repository.getById(
      organizationId: trimmedOrganizationId,
      id: trimmedId,
    );
    if (leadResult is AppFailure<Lead>) return leadResult;
    final lead = (leadResult as AppSuccess<Lead>).value;

    if (!lead.canTransitionTo(LeadStatus.qualified)) {
      return AppFailure<Lead>(
        invalidLeadStatusTransitionFailure(
          from: lead.status,
          to: LeadStatus.qualified,
        ),
      );
    }

    final now = DateTime.now().toUtc();
    final updated = lead.copyWith(
      status: LeadStatus.qualified,
      qualifiedAt: now,
      updatedAt: now,
      updatedBy: trimmedUpdatedBy,
      version: lead.version + 1,
      syncStatus: LeadSyncStatus.pending,
    );

    return _repository.update(lead: updated);
  }
}
