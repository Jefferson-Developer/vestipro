import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/crm_task.dart';
import '../repositories/crm_task_repository.dart';

@injectable
final class ListPendingTasksForCustomerUseCase {
  ListPendingTasksForCustomerUseCase(this._repository);

  final CrmTaskRepository _repository;

  Future<AppResult<List<CrmTask>>> call({
    required String organizationId,
    required String customerId,
    Set<String> responsibleUserIds = const <String>{},
    DateTime? dueBefore,
  }) async {
    final result = await _repository.listPending(
      organizationId: organizationId.trim(),
      responsibleUserIds: responsibleUserIds,
      dueBefore: dueBefore?.toUtc(),
    );

    return result.fold(
      onSuccess: (tasks) => AppSuccess<List<CrmTask>>(
        tasks
            .where(
              (task) =>
                  task.organizationId == organizationId.trim() &&
                  task.customerId == customerId.trim(),
            )
            .toList(growable: false),
      ),
      onFailure: AppFailure<List<CrmTask>>.new,
    );
  }
}
