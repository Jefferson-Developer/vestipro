import '../../domain/entities/app_notification.dart';

sealed class NotificationCenterEvent {
  const NotificationCenterEvent();
}

final class NotificationCenterStarted extends NotificationCenterEvent {
  const NotificationCenterStarted({
    required this.organizationId,
    required this.userId,
  });

  final String organizationId;
  final String userId;
}

final class NotificationCenterRetried extends NotificationCenterEvent {
  const NotificationCenterRetried();
}

final class NotificationCenterRefreshed extends NotificationCenterEvent {
  const NotificationCenterRefreshed();
}

/// `null` clears the filter (shows every category again).
final class NotificationCenterCategoryFilterChanged
    extends NotificationCenterEvent {
  const NotificationCenterCategoryFilterChanged(this.category);

  final AppNotificationCategory? category;
}

/// Requests the next page of the currently-filtered list — never refetches
/// remotely, only widens the visible window over what [listForUser] already
/// returned (see `NotificationCenterState.hasMore`).
final class NotificationCenterMoreRequested extends NotificationCenterEvent {
  const NotificationCenterMoreRequested();
}

/// The user tapped one notification: it must be marked read (if not
/// already) and its `deepLink` resolved by the page's `BuildContext`.
final class NotificationCenterNotificationTapped
    extends NotificationCenterEvent {
  const NotificationCenterNotificationTapped(this.notificationId);

  final String notificationId;
}

final class NotificationCenterMarkAllAsReadRequested
    extends NotificationCenterEvent {
  const NotificationCenterMarkAllAsReadRequested();
}

final class NotificationCenterActionDismissed extends NotificationCenterEvent {
  const NotificationCenterActionDismissed();
}
