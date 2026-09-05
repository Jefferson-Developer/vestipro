/// Reminder urgency for a single [CrmTask] (TASK-152, EPIC-19).
///
/// Used both to decide whether `ProcessCrmTaskReminderUseCase` should
/// dispatch an internal notification at all, and as part of the dedup key
/// `CrmReminderDispatchRepository` uses to avoid re-notifying the same
/// recipient about the same task/urgency combination before its cooldown
/// elapses.
enum CrmTaskReminderClassification {
  /// The task is still pending and due within the configured "due soon"
  /// window (see `CrmReminderSettings.dueSoonWindow`), but not yet overdue.
  dueSoon,

  /// The task is still pending and its `dueAt` has already passed.
  overdue,

  /// No reminder is warranted right now — the task is not pending
  /// (completed/cancelled) or its due date is still further away than the
  /// "due soon" window.
  none,
}
