import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/crm_task.dart';
import '../repositories/crm_task_repository.dart';
import '../value_objects/crm_task_priority.dart';
import '../value_objects/crm_task_status.dart';
import '../value_objects/crm_task_sync_status.dart';
import 'crm_activity_use_case_helpers.dart';

@injectable
final class CreateCrmTaskUseCase {
  CreateCrmTaskUseCase(this._repository);

  final CrmTaskRepository _repository;

  Future<AppResult<CrmTask>> call({
    required String id,
    required String organizationId,
    String? companyId,
    required String title,
    String? description,
    String? customerId,
    String? leadId,
    String? opportunityId,
    String? activityId,
    required String responsibleUserId,
    required DateTime dueAt,
    CrmTaskPriority priority = CrmTaskPriority.medium,
    required String createdBy,
  }) async {
    final trimmedId = id.trim();
    final trimmedOrganizationId = organizationId.trim();
    final trimmedTitle = title.trim();
    final trimmedResponsibleUserId = responsibleUserId.trim();
    final trimmedCreatedBy = createdBy.trim();
    final errors = <String, String>{};

    if (trimmedId.isEmpty) errors['id'] = 'Id is required.';
    if (trimmedOrganizationId.isEmpty) {
      errors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedTitle.isEmpty) errors['title'] = 'Title is required.';
    if (trimmedResponsibleUserId.isEmpty) {
      errors['responsibleUserId'] = 'ResponsibleUserId is required.';
    }
    if (trimmedCreatedBy.isEmpty) {
      errors['createdBy'] = 'CreatedBy is required.';
    }

    if (errors.isNotEmpty) {
      return AppFailure<CrmTask>(
        ValidationFailure(
          'Invalid CRM task creation payload.',
          fieldErrors: errors,
          code: 'invalid_crm_task_create_payload',
        ),
      );
    }

    final now = DateTime.now().toUtc();
    final task = CrmTask(
      id: trimmedId,
      organizationId: trimmedOrganizationId,
      companyId: normalizeCrmOptional(companyId),
      title: trimmedTitle,
      description: normalizeCrmOptional(description),
      customerId: normalizeCrmOptional(customerId),
      leadId: normalizeCrmOptional(leadId),
      opportunityId: normalizeCrmOptional(opportunityId),
      activityId: normalizeCrmOptional(activityId),
      responsibleUserId: trimmedResponsibleUserId,
      dueAt: dueAt.toUtc(),
      priority: priority,
      status: CrmTaskStatus.pending,
      createdAt: now,
      createdBy: trimmedCreatedBy,
      updatedAt: now,
      updatedBy: trimmedCreatedBy,
      version: 1,
      syncStatus: CrmTaskSyncStatus.pending,
    );

    return _repository.create(task: task);
  }
}
