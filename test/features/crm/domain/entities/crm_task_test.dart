import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/crm/crm.dart';

void main() {
  group('CrmTask', () {
    test('calculates overdue only when dueAt is before now and pending', () {
      final now = DateTime.utc(2026, 8, 24, 12);

      expect(_task(dueAt: now).isOverdue(now), isFalse);
      expect(
        _task(dueAt: now.subtract(const Duration(seconds: 1))).isOverdue(now),
        isTrue,
      );
      expect(
        _task(dueAt: now.add(const Duration(seconds: 1))).isOverdue(now),
        isFalse,
      );
      expect(
        _task(
          dueAt: now.subtract(const Duration(seconds: 1)),
          status: CrmTaskStatus.completed,
        ).isOverdue(now),
        isFalse,
      );
    });
  });
}

CrmTask _task({
  required DateTime dueAt,
  CrmTaskStatus status = CrmTaskStatus.pending,
}) {
  final now = DateTime.utc(2026, 8, 24, 9);
  return CrmTask(
    id: 'task-1',
    organizationId: 'org-1',
    title: 'Ligar para cliente',
    responsibleUserId: 'rep-1',
    dueAt: dueAt,
    priority: CrmTaskPriority.medium,
    status: status,
    completedAt: status == CrmTaskStatus.completed ? now : null,
    createdAt: now,
    createdBy: 'rep-1',
    updatedAt: now,
    updatedBy: 'rep-1',
    version: 1,
    syncStatus: CrmTaskSyncStatus.pending,
  );
}
