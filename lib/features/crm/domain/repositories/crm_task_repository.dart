import '../../../../core/utils/utils.dart';
import '../entities/crm_task.dart';

abstract interface class CrmTaskRepository {
  Future<AppResult<CrmTask>> create({required CrmTask task});

  Future<AppResult<CrmTask>> update({required CrmTask task});

  Future<AppResult<CrmTask>> getById({
    required String organizationId,
    required String id,
  });

  Future<AppResult<List<CrmTask>>> listPending({
    required String organizationId,
    Set<String> responsibleUserIds = const <String>{},
    DateTime? dueBefore,
  });
}
