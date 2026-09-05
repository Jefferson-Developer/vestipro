/// Tunable thresholds for CRM task/follow-up reminders (TASK-152, EPIC-19).
///
/// [allowedSendingStartHour]/[allowedSendingEndHour] are a deliberately
/// small, self-contained "quiet hours" guard (default 8h-18h, checked
/// against the device's own local clock) — `tasks.md`/TASK-152 describe the
/// real window rule as "a mesma implementada em TASK-155 (quiet hours), não
/// deve ser duplicada aqui", but TASK-155 (per-user configurable quiet
/// hours/preferences) had not been implemented yet at the time this task
/// ran. Once TASK-155 ships its shared policy, [isWithinAllowedSendingWindow]
/// should be replaced by a call into that policy instead of kept alongside
/// it, so the rule is defined in exactly one place going forward.
final class CrmReminderSettings {
  const CrmReminderSettings({
    this.dueSoonWindow = const Duration(hours: 24),
    this.notificationCooldown = const Duration(hours: 12),
    this.allowedSendingStartHour = 8,
    this.allowedSendingEndHour = 18,
  }) : assert(allowedSendingStartHour >= 0 && allowedSendingStartHour < 24),
       assert(
         allowedSendingEndHour > allowedSendingStartHour &&
             allowedSendingEndHour <= 24,
       );

  /// How far ahead of `dueAt` a still-pending task is already considered
  /// "próxima do vencimento" (see `CrmTaskReminderEvaluator`).
  final Duration dueSoonWindow;

  /// Minimum time between two dispatches for the same
  /// task/recipient/classification combination — the "não é reenviado
  /// repetidamente para a mesma atividade vencida" rule.
  final Duration notificationCooldown;

  /// Inclusive start hour (device-local time, 0-23) of the allowed sending
  /// window.
  final int allowedSendingStartHour;

  /// Exclusive end hour (device-local time, 1-24) of the allowed sending
  /// window.
  final int allowedSendingEndHour;

  /// Whether [localInstant] (already converted to the device's local time
  /// by the caller, e.g. via `DateTime.toLocal()`) falls inside the allowed
  /// sending window.
  bool isWithinAllowedSendingWindow(DateTime localInstant) {
    final hour = localInstant.hour;
    return hour >= allowedSendingStartHour && hour < allowedSendingEndHour;
  }
}
