/// Tunable thresholds for CRM task/follow-up reminders (TASK-152, EPIC-19).
///
/// Used to carry an org-wide "quiet hours" guard
/// (`allowedSendingStartHour`/`allowedSendingEndHour`) before TASK-155
/// shipped the recipient's own per-user, timezone-aware quiet hours
/// (`QuietHours`, via `ResolveNotificationDeliveryTimeUseCase`) — that guard
/// has been removed now that the real, per-recipient policy exists, so the
/// rule is defined in exactly one place, as this class's own doc already
/// anticipated it would be.
final class CrmReminderSettings {
  const CrmReminderSettings({
    this.dueSoonWindow = const Duration(hours: 24),
    this.notificationCooldown = const Duration(hours: 12),
  });

  /// How far ahead of `dueAt` a still-pending task is already considered
  /// "próxima do vencimento" (see `CrmTaskReminderEvaluator`).
  final Duration dueSoonWindow;

  /// Minimum time between two dispatches for the same
  /// task/recipient/classification combination — the "não é reenviado
  /// repetidamente para a mesma atividade vencida" rule.
  final Duration notificationCooldown;
}
