import '../../../../core/utils/utils.dart';
import '../value_objects/crm_task_reminder_classification.dart';

/// Dedup/cooldown ledger for CRM task/follow-up reminders (TASK-152,
/// EPIC-19) — mirrors `TargetAlertDispatchRepository` (TASK-149). Keyed by
/// task + recipient + classification, so:
///
/// - The same task/urgency combination is never re-notified to the same
///   recipient before its cooldown elapses ("não é reenviado repetidamente
///   para a mesma atividade vencida").
/// - A manager and the task's own responsible rep — two different possible
///   recipients for the very same task — each track their own independent
///   cooldown, since including [recipientUserId] in the key.
/// - A task moving from `dueSoon` to `overdue` is treated as a new
///   classification, so it is allowed to notify again even if the
///   `dueSoon` cooldown had not elapsed yet.
abstract interface class CrmReminderDispatchRepository {
  Future<AppResult<DateTime?>> getLastDispatchedAt({
    required String organizationId,
    required String taskId,
    required String recipientUserId,
    required CrmTaskReminderClassification classification,
  });

  Future<AppResult<DateTime>> markDispatched({
    required String organizationId,
    required String taskId,
    required String recipientUserId,
    required CrmTaskReminderClassification classification,
    required DateTime dispatchedAt,
  });
}
