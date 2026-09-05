import '../../../errors/errors.dart';
import '../../domain/entities/app_notification.dart';

enum NotificationCenterLoadStatus { initial, loading, ready, failure }

enum NotificationCenterActionStatus { idle, processing, failure }

/// How many notifications one "page" of the (already fully loaded, bounded)
/// inbox reveals at a time — see `AppPagination`'s `loadMore` mode.
const int kNotificationCenterPageSize = 20;

final class NotificationCenterState {
  const NotificationCenterState({
    this.status = NotificationCenterLoadStatus.initial,
    this.actionStatus = NotificationCenterActionStatus.idle,
    this.organizationId = '',
    this.userId = '',
    this.notifications = const <AppNotification>[],
    this.categoryFilter,
    this.visibleCount = kNotificationCenterPageSize,
    this.failure,
    this.actionFailure,
  });

  final NotificationCenterLoadStatus status;
  final NotificationCenterActionStatus actionStatus;
  final String organizationId;
  final String userId;

  /// Every notification `listForUser` returned for [userId] — already
  /// bounded to `kNotificationInboxRetentionLimit` by the repository, newest
  /// first. Never filtered/paginated itself; use [visibleNotifications].
  final List<AppNotification> notifications;

  /// `null` means "todas as categorias".
  final AppNotificationCategory? categoryFilter;

  /// How many of [filteredNotifications] are currently revealed — grows by
  /// `kNotificationCenterPageSize` on `NotificationCenterMoreRequested`.
  final int visibleCount;

  final Failure? failure;
  final Failure? actionFailure;

  bool get isLoading =>
      status == NotificationCenterLoadStatus.initial ||
      status == NotificationCenterLoadStatus.loading;

  /// Computed from the full [notifications] list (not just the visible
  /// page), so the unread badge is always correct even before the user
  /// scrolls/loads further pages.
  int get unreadCount =>
      notifications.where((notification) => notification.readAt == null).length;

  List<AppNotification> get filteredNotifications {
    final filter = categoryFilter;
    if (filter == null) return notifications;
    return notifications
        .where((notification) => notification.category == filter)
        .toList(growable: false);
  }

  List<AppNotification> get visibleNotifications {
    final filtered = filteredNotifications;
    return visibleCount >= filtered.length
        ? filtered
        : filtered.take(visibleCount).toList(growable: false);
  }

  bool get hasMore => visibleCount < filteredNotifications.length;

  NotificationCenterState copyWith({
    NotificationCenterLoadStatus? status,
    NotificationCenterActionStatus? actionStatus,
    String? organizationId,
    String? userId,
    List<AppNotification>? notifications,
    AppNotificationCategory? categoryFilter,
    bool clearCategoryFilter = false,
    int? visibleCount,
    Failure? failure,
    bool clearFailure = false,
    Failure? actionFailure,
    bool clearActionFailure = false,
  }) {
    return NotificationCenterState(
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      organizationId: organizationId ?? this.organizationId,
      userId: userId ?? this.userId,
      notifications: notifications ?? this.notifications,
      categoryFilter: clearCategoryFilter
          ? null
          : categoryFilter ?? this.categoryFilter,
      visibleCount: visibleCount ?? this.visibleCount,
      failure: clearFailure ? null : failure ?? this.failure,
      actionFailure: clearActionFailure
          ? null
          : actionFailure ?? this.actionFailure,
    );
  }
}
