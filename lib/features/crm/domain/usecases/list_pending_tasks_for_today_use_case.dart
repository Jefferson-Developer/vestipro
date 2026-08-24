import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/crm_task.dart';
import '../repositories/crm_task_repository.dart';

@injectable
final class ListPendingTasksForTodayUseCase {
  ListPendingTasksForTodayUseCase(this._repository);

  final CrmTaskRepository _repository;

  Future<AppResult<List<CrmTask>>> call({
    required String organizationId,
    Set<String> responsibleUserIds = const <String>{},
    required DateTime now,
  }) {
    final tomorrow = DateTime.utc(now.year, now.month, now.day + 1);
    return _repository.listPending(
      organizationId: organizationId.trim(),
      responsibleUserIds: responsibleUserIds,
      dueBefore: tomorrow,
    );
  }
}
