import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/crm_task.dart';
import '../repositories/crm_task_repository.dart';

@injectable
final class ListPendingTasksForWeekUseCase {
  ListPendingTasksForWeekUseCase(this._repository);

  final CrmTaskRepository _repository;

  Future<AppResult<List<CrmTask>>> call({
    required String organizationId,
    Set<String> responsibleUserIds = const <String>{},
    required DateTime now,
  }) {
    final weekLimit = DateTime.utc(now.year, now.month, now.day + 7);
    return _repository.listPending(
      organizationId: organizationId.trim(),
      responsibleUserIds: responsibleUserIds,
      dueBefore: weekLimit,
    );
  }
}
