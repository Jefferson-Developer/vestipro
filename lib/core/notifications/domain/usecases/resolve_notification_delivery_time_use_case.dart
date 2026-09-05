import 'package:injectable/injectable.dart';

import '../../../utils/utils.dart';
import '../entities/app_notification.dart';
import '../entities/communication_preferences.dart';
import '../repositories/communication_preferences_repository.dart';

/// Computes `AppNotification.deliverAt` for a notification about to be
/// created (TASK-155) — every generator (`ProcessCrmTaskReminderUseCase` —
/// TASK-152 —, `ProcessTargetAlertUseCase`/`ProcessOrderCommercialAlertUseCase`/
/// `ProcessInsightCommercialAlertUseCase` — TASK-153) calls this right
/// before building the `AppNotification` it is about to persist, mirroring
/// how they already call `ShouldDispatchNotificationUseCase` first
/// (TASK-154) — the two gates are deliberately kept independent: one
/// decides *whether* a category/channel is muted, this one decides *when*
/// an allowed notification is actually shown.
///
/// [priority] TASK-154/TASK-155's shared exception:
/// [AppNotificationPriority.critical] always resolves to `null` (deliver
/// immediately), even while the recipient's quiet hours are active — a
/// security/session-critical alert, a pedido rejeitado, a falha crítica de
/// sincronização must never wait for quiet hours to end.
@injectable
final class ResolveNotificationDeliveryTimeUseCase {
  const ResolveNotificationDeliveryTimeUseCase(this._preferencesRepository);

  final CommunicationPreferencesRepository _preferencesRepository;

  /// Returns `null` when [notification's future `deliverAt`] should stay
  /// unset (deliver now): either [priority] is
  /// [AppNotificationPriority.critical], the recipient never enabled quiet
  /// hours, or [now] simply falls outside their configured window.
  /// Otherwise returns the next UTC instant quiet hours end for this
  /// recipient — `QuietHours.nextAllowedInstant`, computed from their own
  /// last-synced device timezone, never the caller's.
  Future<DateTime?> call({
    required String organizationId,
    required String userId,
    required AppNotificationPriority priority,
    DateTime? now,
  }) async {
    if (priority == AppNotificationPriority.critical) return null;

    final instant = (now ?? DateTime.now()).toUtc();
    final result = await _preferencesRepository.get(
      organizationId: organizationId,
      userId: userId,
    );
    final preferences = switch (result) {
      AppSuccess<CommunicationPreferences>(value: final value) => value,
      // Fails open, same "an unreadable preference must never silently
      // swallow/delay a notification" precedent
      // `ShouldDispatchNotificationUseCase` already documents.
      AppFailure<CommunicationPreferences>() => null,
    };
    if (preferences == null) return null;

    if (!preferences.quietHours.isActiveAt(instant)) return null;
    return preferences.quietHours.nextAllowedInstant(instant);
  }
}
