import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/lead.dart';
import '../repositories/lead_repository.dart';
import '../value_objects/lead_source.dart';
import '../value_objects/lead_status.dart';
import '../value_objects/lead_sync_status.dart';
import 'lead_use_case_helpers.dart';

/// Creates a Lead at the entry point of the commercial funnel.
///
/// A newly created Lead always starts as [LeadStatus.newLead]; moving it
/// forward is the job of `MarkLeadContactedUseCase`, `QualifyLeadUseCase`,
/// `DisqualifyLeadUseCase` and the conversion use cases.
@injectable
final class CreateLeadUseCase {
  CreateLeadUseCase(this._repository);

  final LeadRepository _repository;

  Future<AppResult<Lead>> call({
    required String id,
    required String organizationId,
    String? companyId,
    required String name,
    String? document,
    required LeadSource source,
    required String responsibleUserId,
    int score = 0,
    required String createdBy,
  }) async {
    final trimmedId = id.trim();
    final trimmedOrganizationId = organizationId.trim();
    final trimmedName = name.trim();
    final trimmedResponsibleUserId = responsibleUserId.trim();
    final trimmedCreatedBy = createdBy.trim();
    final fieldErrors = <String, String>{};

    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedName.isEmpty) fieldErrors['name'] = 'Name is required.';
    if (trimmedResponsibleUserId.isEmpty) {
      fieldErrors['responsibleUserId'] = 'ResponsibleUserId is required.';
    }
    if (trimmedCreatedBy.isEmpty) {
      fieldErrors['createdBy'] = 'CreatedBy is required.';
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure<Lead>(
        ValidationFailure(
          'Invalid lead creation payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_lead_create_payload',
        ),
      );
    }

    final now = DateTime.now().toUtc();
    final lead = Lead(
      id: trimmedId,
      organizationId: trimmedOrganizationId,
      companyId: normalizeLeadOptional(companyId),
      name: trimmedName,
      document: normalizeLeadOptional(document),
      source: source,
      responsibleUserId: trimmedResponsibleUserId,
      status: LeadStatus.newLead,
      score: score,
      createdAt: now,
      createdBy: trimmedCreatedBy,
      updatedAt: now,
      updatedBy: trimmedCreatedBy,
      version: 1,
      syncStatus: LeadSyncStatus.pending,
    );

    return _repository.create(lead: lead);
  }
}
