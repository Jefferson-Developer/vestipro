import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/crm/crm.dart';

void main() {
  group('CRM task use cases', () {
    late _InMemoryCrmTaskRepository repository;

    setUp(() {
      repository = _InMemoryCrmTaskRepository();
    });

    test(
      'completes task and rejects non-responsible user without manager flag',
      () async {
        repository.seed(_task(id: 'task-1', responsibleUserId: 'rep-1'));
        final useCase = CompleteCrmTaskUseCase(repository);

        final denied = await useCase(
          organizationId: 'org-1',
          id: 'task-1',
          actorUserId: 'rep-2',
        );
        expect(denied, isA<AppFailure<CrmTask>>());
        expect(
          (denied as AppFailure<CrmTask>).failure,
          isA<PermissionFailure>(),
        );

        final allowed = await useCase(
          organizationId: 'org-1',
          id: 'task-1',
          actorUserId: 'manager-1',
          actorCanManageOthers: true,
          completedAt: DateTime.utc(2026, 8, 24, 14),
        );

        final task = (allowed as AppSuccess<CrmTask>).value;
        expect(task.status, CrmTaskStatus.completed);
        expect(task.completedAt, DateTime.utc(2026, 8, 24, 14));
        expect(task.updatedBy, 'manager-1');
        expect(task.version, 2);
        expect(task.syncStatus, CrmTaskSyncStatus.pending);
      },
    );

    test('reschedules task preserving previous due dates', () async {
      final originalDueAt = DateTime.utc(2026, 8, 24, 10);
      final newDueAt = DateTime.utc(2026, 8, 26, 10);
      repository.seed(_task(id: 'task-1', dueAt: originalDueAt));
      final useCase = RescheduleCrmTaskUseCase(repository);

      final result = await useCase(
        organizationId: 'org-1',
        id: 'task-1',
        actorUserId: 'rep-1',
        newDueAt: newDueAt,
      );

      final task = (result as AppSuccess<CrmTask>).value;
      expect(task.dueAt, newDueAt);
      expect(task.previousDueDates, <DateTime>[originalDueAt]);
      expect(task.updatedBy, 'rep-1');
      expect(task.version, 2);
    });
  });
}

CrmTask _task({
  required String id,
  String responsibleUserId = 'rep-1',
  DateTime? dueAt,
}) {
  final now = DateTime.utc(2026, 8, 24, 9);
  return CrmTask(
    id: id,
    organizationId: 'org-1',
    title: 'Ligar para cliente',
    responsibleUserId: responsibleUserId,
    dueAt: dueAt ?? DateTime.utc(2026, 8, 24, 10),
    priority: CrmTaskPriority.high,
    status: CrmTaskStatus.pending,
    createdAt: now,
    createdBy: 'rep-1',
    updatedAt: now,
    updatedBy: 'rep-1',
    version: 1,
    syncStatus: CrmTaskSyncStatus.synced,
  );
}

final class _InMemoryCrmTaskRepository implements CrmTaskRepository {
  final Map<String, CrmTask> tasks = <String, CrmTask>{};

  void seed(CrmTask task) => tasks[task.id] = task;

  @override
  Future<AppResult<CrmTask>> create({required CrmTask task}) async {
    tasks[task.id] = task;
    return AppSuccess<CrmTask>(task);
  }

  @override
  Future<AppResult<CrmTask>> update({required CrmTask task}) async {
    tasks[task.id] = task;
    return AppSuccess<CrmTask>(task);
  }

  @override
  Future<AppResult<CrmTask>> getById({
    required String organizationId,
    required String id,
  }) async {
    final task = tasks[id];
    if (task == null || task.organizationId != organizationId) {
      return const AppFailure<CrmTask>(
        NotFoundFailure('CRM task not found.', code: 'crm_task_not_found'),
      );
    }
    return AppSuccess<CrmTask>(task);
  }

  @override
  Future<AppResult<List<CrmTask>>> listPending({
    required String organizationId,
    Set<String> responsibleUserIds = const <String>{},
    DateTime? dueBefore,
  }) {
    throw UnimplementedError();
  }
}
