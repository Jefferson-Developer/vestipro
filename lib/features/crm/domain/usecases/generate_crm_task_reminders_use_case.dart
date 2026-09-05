import 'package:injectable/injectable.dart';

import '../entities/crm_task.dart';
import '../value_objects/crm_reminder_settings.dart';
import 'process_crm_task_reminder_use_case.dart';

/// Orchestrates CRM task/follow-up reminders (TASK-152, EPIC-19) for a
/// batch of already-loaded [CrmTask]s, running client-side wherever CRM
/// tasks themselves already live — there is no server-side Cloud Function
/// or scheduled trigger for this today because `CrmTask` (TASK-060) has no
/// Firestore-backed repository yet (`SharedPreferencesCrmTaskRepository` is
/// local-only), so a Cloud Function would have nothing to read. This
/// mirrors the same client-triggered pattern `ProcessTargetAlertUseCase`
/// (TASK-149) already established for target alerts, evaluated whenever
/// `CrmTaskListBloc` loads the caller's tasks (their own, plus their team's
/// when they can manage others).
@injectable
final class GenerateCrmTaskRemindersUseCase {
  GenerateCrmTaskRemindersUseCase(this._processReminder);

  final ProcessCrmTaskReminderUseCase _processReminder;

  /// Returns how many notifications were actually dispatched (mainly for
  /// tests/telemetry — callers are not expected to react to the count).
  Future<int> call({
    required List<CrmTask> tasks,
    required String recipientUserId,
    required DateTime now,
    CrmReminderSettings settings = const CrmReminderSettings(),
  }) async {
    var dispatched = 0;
    for (final task in tasks) {
      final wasDispatched = await _processReminder(
        task: task,
        recipientUserId: recipientUserId,
        now: now,
        settings: settings,
      );
      if (wasDispatched) dispatched += 1;
    }
    return dispatched;
  }
}
