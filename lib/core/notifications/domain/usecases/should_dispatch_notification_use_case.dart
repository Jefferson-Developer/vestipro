import 'package:injectable/injectable.dart';

import '../../../utils/utils.dart';
import '../entities/app_notification.dart';
import '../entities/communication_preferences.dart';
import '../repositories/communication_preferences_repository.dart';

/// The gate every notification generator (`ProcessCrmTaskReminderUseCase` —
/// TASK-152 —, `ProcessTargetAlertUseCase`/`ProcessOrderCommercialAlertUseCase`/
/// `ProcessInsightCommercialAlertUseCase` — TASK-153 —, and TASK-155's quiet
/// hours later) consults before writing an [AppNotification]: TASK-154's
/// "todo gerador de notificação deve consultar estas preferências antes de
/// enviar" requirement, centralized in one place instead of every generator
/// re-reading [CommunicationPreferencesRepository] itself.
///
/// Every existing generator only ever writes to the central de notificações
/// internas (TASK-151) — no generator sends a real push or e-mail yet — so
/// [channel] defaults to [CommunicationChannel.inApp], the one channel this
/// gate actually has an effect on today.
@injectable
final class ShouldDispatchNotificationUseCase {
  const ShouldDispatchNotificationUseCase(this._repository);

  final CommunicationPreferencesRepository _repository;

  Future<bool> call({
    required String organizationId,
    required String userId,
    required AppNotificationCategory category,
    CommunicationChannel channel = CommunicationChannel.inApp,
  }) async {
    final result = await _repository.get(
      organizationId: organizationId,
      userId: userId,
    );
    return switch (result) {
      AppSuccess<CommunicationPreferences>(value: final preferences) =>
        preferences.allows(category, channel),
      // Fails open: an unreadable preference must never silently swallow a
      // notification the user never actually asked to mute — same
      // "the notification center must stay usable even when a read fails"
      // precedent `NotificationInboxRepository` already documents.
      AppFailure<CommunicationPreferences>() => true,
    };
  }
}
