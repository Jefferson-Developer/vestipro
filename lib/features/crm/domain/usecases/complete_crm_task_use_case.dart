import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/crm_task.dart';
import '../repositories/crm_task_repository.dart';
import '../value_objects/crm_task_status.dart';
import '../value_objects/crm_task_sync_status.dart';

@injectable
final class CompleteCrmTaskUseCase {
  CompleteCrmTaskUseCase(this._repository);

  final CrmTaskRepository _repository;

  Future<AppResult<CrmTask>> call({
    required String organizationId,
    required String id,
    required String actorUserId,
    bool actorCanManageOthers = false,
    DateTime? completedAt,
  }) async {
    final taskResult = await _loadTask(organizationId: organizationId, id: id);
    if (taskResult is AppFailure<CrmTask>) return taskResult;
    final task = (taskResult as AppSuccess<CrmTask>).value;
    final actor = actorUserId.trim();

    if (!task.canBeChangedBy(
      actorUserId: actor,
      actorCanManageOthers: actorCanManageOthers,
    )) {
      return const AppFailure<CrmTask>(
        PermissionFailure(
          'Only the responsible user or a manager can complete this task.',
          code: 'crm_task_complete_denied',
        ),
      );
    }
    if (task.status == CrmTaskStatus.completed) {
      return const AppFailure<CrmTask>(
        ConflictFailure(
          'CRM task is already completed.',
          code: 'crm_task_already_completed',
        ),
      );
    }

    final now = (completedAt ?? DateTime.now()).toUtc();
    return _repository.update(
      task: task.copyWith(
        status: CrmTaskStatus.completed,
        completedAt: now,
        updatedAt: now,
        updatedBy: actor,
        version: task.version + 1,
        syncStatus: CrmTaskSyncStatus.pending,
      ),
    );
  }

  Future<AppResult<CrmTask>> _loadTask({
    required String organizationId,
    required String id,
  }) {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedId = id.trim();
    if (trimmedOrganizationId.isEmpty || trimmedId.isEmpty) {
      return Future.value(
        const AppFailure<CrmTask>(
          ValidationFailure(
            'Invalid CRM task lookup payload.',
            code: 'invalid_crm_task_lookup_payload',
          ),
        ),
      );
    }
    return _repository.getById(
      organizationId: trimmedOrganizationId,
      id: trimmedId,
    );
  }
}
