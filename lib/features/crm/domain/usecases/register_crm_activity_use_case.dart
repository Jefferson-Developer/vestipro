import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/crm_activity.dart';
import '../repositories/crm_activity_repository.dart';
import '../value_objects/crm_activity_sync_status.dart';
import '../value_objects/crm_activity_type.dart';
import 'crm_activity_use_case_helpers.dart';

@injectable
final class RegisterCrmActivityUseCase {
  RegisterCrmActivityUseCase(this._repository);

  final CrmActivityRepository _repository;

  Future<AppResult<CrmActivity>> call({
    required String id,
    required String organizationId,
    String? companyId,
    required CrmActivityType type,
    String? customerId,
    String? leadId,
    String? opportunityId,
    required String userId,
    DateTime? occurredAt,
    required String description,
    int? durationMinutes,
    List<String> attachmentUrls = const <String>[],
  }) async {
    final trimmedId = id.trim();
    final trimmedOrganizationId = organizationId.trim();
    final trimmedUserId = userId.trim();
    final trimmedDescription = description.trim();
    final normalizedCustomerId = normalizeCrmOptional(customerId);
    final normalizedLeadId = normalizeCrmOptional(leadId);
    final normalizedOpportunityId = normalizeCrmOptional(opportunityId);
    final fieldErrors = <String, String>{};

    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedUserId.isEmpty) fieldErrors['userId'] = 'UserId is required.';
    if (trimmedDescription.isEmpty) {
      fieldErrors['description'] = 'Description is required.';
    }
    if (normalizedCustomerId == null &&
        normalizedLeadId == null &&
        normalizedOpportunityId == null) {
      fieldErrors['link'] =
          'At least one customer, lead or opportunity link is required.';
    }
    if (durationMinutes != null && durationMinutes < 0) {
      fieldErrors['durationMinutes'] = 'Duration cannot be negative.';
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure<CrmActivity>(
        ValidationFailure(
          'Invalid CRM activity registration payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_crm_activity_register_payload',
        ),
      );
    }

    final now = DateTime.now().toUtc();
    final activity = CrmActivity(
      id: trimmedId,
      organizationId: trimmedOrganizationId,
      companyId: normalizeCrmOptional(companyId),
      type: type,
      customerId: normalizedCustomerId,
      leadId: normalizedLeadId,
      opportunityId: normalizedOpportunityId,
      userId: trimmedUserId,
      occurredAt: (occurredAt ?? now).toUtc(),
      description: trimmedDescription,
      durationMinutes: durationMinutes,
      attachmentUrls: normalizeCrmAttachments(attachmentUrls),
      createdAt: now,
      createdBy: trimmedUserId,
      updatedAt: now,
      updatedBy: trimmedUserId,
      version: 1,
      syncStatus: CrmActivitySyncStatus.pending,
    );

    return _repository.create(activity: activity);
  }
}
