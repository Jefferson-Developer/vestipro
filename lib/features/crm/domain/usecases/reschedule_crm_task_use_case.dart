import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/crm_task.dart';
import '../repositories/crm_task_repository.dart';
import '../value_objects/crm_task_status.dart';
import '../value_objects/crm_task_sync_status.dart';

@injectable
final class RescheduleCrmTaskUseCase {
  RescheduleCrmTaskUseCase(this._repository);

  final CrmTaskRepository _repository;

  Future<AppResult<CrmTask>> call({
    required String organizationId,
    required String id,
    required String actorUserId,
    required DateTime newDueAt,
    bool actorCanManageOthers = false,
  }) async {
    final taskResult = await _repository.getById(
      organizationId: organizationId.trim(),
      id: id.trim(),
    );
    if (taskResult is AppFailure<CrmTask>) return taskResult;
    final task = (taskResult as AppSuccess<CrmTask>).value;
    final actor = actorUserId.trim();

    if (!task.canBeChangedBy(
      actorUserId: actor,
      actorCanManageOthers: actorCanManageOthers,
    )) {
      return const AppFailure<CrmTask>(
        PermissionFailure(
          'Only the responsible user or a manager can reschedule this task.',
          code: 'crm_task_reschedule_denied',
        ),
      );
    }
    if (task.status == CrmTaskStatus.completed) {
      return const AppFailure<CrmTask>(
        ConflictFailure(
          'Completed CRM tasks cannot be rescheduled.',
          code: 'crm_task_reschedule_completed',
        ),
      );
    }

    final now = DateTime.now().toUtc();
    return _repository.update(
      task: task.copyWith(
        dueAt: newDueAt.toUtc(),
        previousDueDates: <DateTime>[...task.previousDueDates, task.dueAt],
        updatedAt: now,
        updatedBy: actor,
        version: task.version + 1,
        syncStatus: CrmTaskSyncStatus.pending,
      ),
    );
  }
}
