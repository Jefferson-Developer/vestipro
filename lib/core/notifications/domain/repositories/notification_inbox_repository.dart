import '../../../utils/utils.dart';
import '../entities/app_notification.dart';

/// Source of truth for internal notifications shown by the app itself,
/// independent from push delivery availability (TASK-150/TASK-151).
///
/// Every implementation must keep [create] working fully offline — several
/// callers (e.g. `ProcessTargetAlertUseCase`) run in the field without
/// connectivity — and must never let a `listForUser` failure hide the last
/// synced notifications: falling back to whatever was last cached locally is
/// always preferred over surfacing an error, since the notification center
/// must stay usable offline.
abstract interface class NotificationInboxRepository {
  Future<AppResult<AppNotification>> create({
    required AppNotification notification,
  });

  /// Bounded to the last [kNotificationInboxRetentionLimit] notifications
  /// for [userId], newest first. Never returns a notification belonging to
  /// another user or organization. Never returns a notification still
  /// suppressed by the recipient's own quiet hours either (TASK-155) —
  /// `AppNotification.deliverAt` still in the future — even though it is
  /// already durably persisted; it simply appears on a later call once that
  /// instant passes.
  Future<AppResult<List<AppNotification>>> listForUser({
    required String organizationId,
    required String userId,
  });

  /// Marks a single notification as read. Idempotent — marking an
  /// already-read notification again keeps its original [DateTime] intent
  /// (callers may pass an explicit [readAt] for deterministic tests).
  Future<AppResult<void>> markAsRead({
    required String organizationId,
    required String userId,
    required String notificationId,
    DateTime? readAt,
  });

  /// Marks every currently-unread notification for [userId] as read in one
  /// operation (the "marcar todas como lidas" action).
  Future<AppResult<void>> markAllAsRead({
    required String organizationId,
    required String userId,
    DateTime? readAt,
  });
}

/// How many notifications the inbox keeps available (locally cached and
/// fetched remotely) per user before the oldest ones age out — the simple
/// retention guard TASK-151 requires ahead of TASK-160's fuller archiving
/// policy.
const int kNotificationInboxRetentionLimit = 200;
