import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/crm/crm.dart';

void main() {
  group('CrmTaskListPage', () {
    late _InMemoryCrmTaskRepository repository;
    late FakeAnalyticsService analyticsService;
    final now = DateTime.utc(2026, 8, 24, 12);

    setUp(() {
      repository = _InMemoryCrmTaskRepository()
        ..seed(
          _task(
            id: 'late',
            title: 'Visita atrasada',
            dueAt: now.subtract(const Duration(hours: 2)),
          ),
        )
        ..seed(
          _task(
            id: 'today',
            title: 'Ligar hoje',
            dueAt: now.add(const Duration(hours: 2)),
          ),
        )
        ..seed(
          _task(
            id: 'week',
            title: 'Enviar proposta',
            dueAt: now.add(const Duration(days: 2)),
          ),
        );
      analyticsService = FakeAnalyticsService();
    });

    testWidgets('groups overdue, today and week tasks with overdue badge', (
      tester,
    ) async {
      await _pumpPage(tester, repository, analyticsService, now);
      await tester.pumpAndSettle();

      expect(find.text('Atrasadas'), findsOneWidget);
      expect(find.text('Hoje'), findsOneWidget);
      expect(find.text('Esta semana'), findsOneWidget);
      expect(find.text('Visita atrasada'), findsOneWidget);
      expect(find.text('Ligar hoje'), findsOneWidget);
      expect(find.text('Enviar proposta'), findsOneWidget);
      expect(find.text('Atrasada'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_outlined), findsWidgets);
    });

    testWidgets('completes a task in one tap and logs analytics', (
      tester,
    ) async {
      await _pumpPage(tester, repository, analyticsService, now);
      await tester.pumpAndSettle();

      final lateTask = find.byKey(const Key('crm-task-late'));
      expect(lateTask, findsOneWidget);
      await tester.tap(
        find.descendant(of: lateTask, matching: find.text('Concluir')),
      );
      await tester.pumpAndSettle();

      expect(repository.tasks['late']!.status, CrmTaskStatus.completed);
      expect(find.text('Visita atrasada'), findsNothing);
      expect(
        analyticsService.loggedEvents.where(
          (event) => event.name == AnalyticsEvents.crmFollowupCompleted,
        ),
        hasLength(1),
      );
    });
  });
}

Future<void> _pumpPage(
  WidgetTester tester,
  _InMemoryCrmTaskRepository repository,
  FakeAnalyticsService analyticsService,
  DateTime now,
) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: CrmTaskListPage(
        organizationId: 'org-1',
        userId: 'rep-1',
        now: () => now,
        createBloc: () => CrmTaskListBloc(
          listPendingTasksForWeek: ListPendingTasksForWeekUseCase(repository),
          completeTask: CompleteCrmTaskUseCase(repository),
          analyticsService: analyticsService,
        ),
      ),
    ),
  );
}

CrmTask _task({
  required String id,
  required String title,
  required DateTime dueAt,
}) {
  final createdAt = DateTime.utc(2026, 8, 20);
  return CrmTask(
    id: id,
    organizationId: 'org-1',
    title: title,
    responsibleUserId: 'rep-1',
    dueAt: dueAt,
    priority: CrmTaskPriority.high,
    status: CrmTaskStatus.pending,
    createdAt: createdAt,
    createdBy: 'rep-1',
    updatedAt: createdAt,
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
  }) async {
    final dueLimit = dueBefore;
    final visible =
        tasks.values
            .where(
              (task) =>
                  task.organizationId == organizationId &&
                  task.status == CrmTaskStatus.pending &&
                  (responsibleUserIds.isEmpty ||
                      responsibleUserIds.contains(task.responsibleUserId)) &&
                  (dueLimit == null || task.dueAt.isBefore(dueLimit)),
            )
            .toList(growable: false)
          ..sort((first, second) => first.dueAt.compareTo(second.dueAt));
    return AppSuccess<List<CrmTask>>(visible);
  }
}
