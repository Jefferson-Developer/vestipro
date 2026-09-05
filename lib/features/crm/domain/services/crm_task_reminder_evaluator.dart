import '../entities/crm_task.dart';
import '../value_objects/crm_reminder_settings.dart';
import '../value_objects/crm_task_reminder_classification.dart';
import '../value_objects/crm_task_status.dart';

/// Pure classification of a single [CrmTask] into a reminder urgency
/// (TASK-152, EPIC-19) — mirrors `TargetAlertEvaluator` (TASK-149): no I/O,
/// no dedup/cooldown logic (that lives in `ProcessCrmTaskReminderUseCase`
/// via `CrmReminderDispatchRepository`), just "what urgency does this task
/// have right now".
final class CrmTaskReminderEvaluator {
  const CrmTaskReminderEvaluator();

  CrmTaskReminderClassification classify({
    required CrmTask task,
    required DateTime now,
    CrmReminderSettings settings = const CrmReminderSettings(),
  }) {
    if (task.status != CrmTaskStatus.pending) {
      return CrmTaskReminderClassification.none;
    }

    final instant = now.toUtc();
    if (task.dueAt.isBefore(instant)) {
      return CrmTaskReminderClassification.overdue;
    }
    if (task.dueAt.difference(instant) <= settings.dueSoonWindow) {
      return CrmTaskReminderClassification.dueSoon;
    }
    return CrmTaskReminderClassification.none;
  }
}
