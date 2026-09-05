import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/crm/crm.dart';

void main() {
  group('CrmTaskReminderEvaluator', () {
    const evaluator = CrmTaskReminderEvaluator();
    final now = DateTime.utc(2026, 9, 5, 12);

    test('classifies a pending task past its due date as overdue', () {
      final task = _buildTask(dueAt: now.subtract(const Duration(hours: 1)));

      expect(
        evaluator.classify(task: task, now: now),
        CrmTaskReminderClassification.overdue,
      );
    });

    test(
      'classifies a pending task due within the due-soon window as dueSoon',
      () {
        final task = _buildTask(dueAt: now.add(const Duration(hours: 6)));

        expect(
          evaluator.classify(task: task, now: now),
          CrmTaskReminderClassification.dueSoon,
        );
      },
    );

    test('classifies a pending task far from its due date as none', () {
      final task = _buildTask(dueAt: now.add(const Duration(days: 5)));

      expect(
        evaluator.classify(task: task, now: now),
        CrmTaskReminderClassification.none,
      );
    });

    test('classifies a completed task as none even if overdue', () {
      final task = _buildTask(
        dueAt: now.subtract(const Duration(hours: 1)),
        status: CrmTaskStatus.completed,
      );

      expect(
        evaluator.classify(task: task, now: now),
        CrmTaskReminderClassification.none,
      );
    });
  });
}

CrmTask _buildTask({
  required DateTime dueAt,
  CrmTaskStatus status = CrmTaskStatus.pending,
}) {
  final createdAt = DateTime.utc(2026, 9, 1);
  return CrmTask(
    id: 'task-1',
    organizationId: 'org-1',
    title: 'Ligar para o cliente',
    customerId: 'customer-1',
    responsibleUserId: 'rep-1',
    dueAt: dueAt,
    priority: CrmTaskPriority.medium,
    status: status,
    createdAt: createdAt,
    createdBy: 'rep-1',
    updatedAt: createdAt,
    updatedBy: 'rep-1',
    version: 1,
    syncStatus: CrmTaskSyncStatus.synced,
  );
}
