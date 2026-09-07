import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../utils/utils.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/usecases/list_notifications_for_user_use_case.dart';
import '../../domain/usecases/mark_all_notifications_as_read_use_case.dart';
import '../../domain/usecases/mark_notification_as_read_use_case.dart';
import 'notification_center_event.dart';
import 'notification_center_state.dart';

/// Drives the central de notificações internas (TASK-151): loading,
/// category filtering, client-side pagination over the already-fetched
/// (bounded) inbox, marking one/all notifications as read and keeping the
/// unread badge (`NotificationCenterState.unreadCount`) correct after every
/// mutation.
///
/// Deliberately does not navigate itself — [NotificationCenterNotificationTapped]
/// only marks the notification read; the page's own `onTap` callback (which
/// already has the tapped [AppNotification], deepLink included, and a real
/// `BuildContext`) is what calls `context.go(...)`, keeping this bloc free
/// of any `go_router`/navigation dependency and easy to unit test.
@injectable
final class NotificationCenterBloc
    extends Bloc<NotificationCenterEvent, NotificationCenterState> {
  NotificationCenterBloc({
    required this.listNotificationsForUser,
    required this.markNotificationAsRead,
    required this.markAllNotificationsAsRead,
  }) : super(const NotificationCenterState()) {
    on<NotificationCenterStarted>(_onStarted);
    on<NotificationCenterRetried>(_onRetried);
    on<NotificationCenterRefreshed>(_onRefreshed);
    on<NotificationCenterCategoryFilterChanged>(_onCategoryFilterChanged);
    on<NotificationCenterMoreRequested>(_onMoreRequested);
    on<NotificationCenterNotificationTapped>(_onNotificationTapped);
    on<NotificationCenterMarkAllAsReadRequested>(_onMarkAllAsReadRequested);
    on<NotificationCenterActionDismissed>(_onActionDismissed);
  }

  final ListNotificationsForUserUseCase listNotificationsForUser;
  final MarkNotificationAsReadUseCase markNotificationAsRead;
  final MarkAllNotificationsAsReadUseCase markAllNotificationsAsRead;

  Future<void> _onStarted(
    NotificationCenterStarted event,
    Emitter<NotificationCenterState> emit,
  ) async {
    emit(
      const NotificationCenterState().copyWith(
        status: NotificationCenterLoadStatus.loading,
        organizationId: event.organizationId,
        userId: event.userId,
        clearFailure: true,
      ),
    );
    await _load(emit);
  }

  Future<void> _onRetried(
    NotificationCenterRetried event,
    Emitter<NotificationCenterState> emit,
  ) async {
    emit(
      state.copyWith(
        status: NotificationCenterLoadStatus.loading,
        clearFailure: true,
      ),
    );
    await _load(emit);
  }

  /// Reloads silently (no full-screen loading state) — meant for
  /// pull-to-refresh, where the list stays visible while it refetches.
  Future<void> _onRefreshed(
    NotificationCenterRefreshed event,
    Emitter<NotificationCenterState> emit,
  ) async {
    await _load(emit);
  }

  Future<void> _load(Emitter<NotificationCenterState> emit) async {
    final result = await listNotificationsForUser(
      organizationId: state.organizationId,
      userId: state.userId,
    );
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess<List<AppNotification>>(value: final notifications):
        emit(
          state.copyWith(
            status: NotificationCenterLoadStatus.ready,
            notifications: notifications,
            clearFailure: true,
          ),
        );
      case AppFailure<List<AppNotification>>(failure: final failure):
        emit(
          state.copyWith(
            status: NotificationCenterLoadStatus.failure,
            failure: failure,
          ),
        );
    }
  }

  void _onCategoryFilterChanged(
    NotificationCenterCategoryFilterChanged event,
    Emitter<NotificationCenterState> emit,
  ) {
    emit(
      state.copyWith(
        categoryFilter: event.category,
        clearCategoryFilter: event.category == null,
        visibleCount: kNotificationCenterPageSize,
      ),
    );
  }

  void _onMoreRequested(
    NotificationCenterMoreRequested event,
    Emitter<NotificationCenterState> emit,
  ) {
    if (!state.hasMore) return;
    emit(
      state.copyWith(
        visibleCount: state.visibleCount + kNotificationCenterPageSize,
      ),
    );
  }

  Future<void> _onNotificationTapped(
    NotificationCenterNotificationTapped event,
    Emitter<NotificationCenterState> emit,
  ) async {
    final target = state.notifications.where(
      (notification) => notification.id == event.notificationId,
    );
    if (target.isEmpty || target.first.readAt != null) {
      return;
    }

    final readAt = DateTime.now().toUtc();
    emit(
      state.copyWith(
        notifications: <AppNotification>[
          for (final notification in state.notifications)
            if (notification.id == event.notificationId)
              _withReadAt(notification, readAt)
            else
              notification,
        ],
      ),
    );

    final result = await markNotificationAsRead(
      organizationId: state.organizationId,
      userId: state.userId,
      notificationId: event.notificationId,
      readAt: readAt,
    );
    if (emit.isDone) return;
    if (result is AppFailure<void>) {
      // Marking as read failing is not worth interrupting the navigation
      // the caller already triggered — the next full reload reconciles the
      // real state; this bloc only avoids leaving a stale `actionFailure`
      // behind.
      return;
    }
  }

  Future<void> _onMarkAllAsReadRequested(
    NotificationCenterMarkAllAsReadRequested event,
    Emitter<NotificationCenterState> emit,
  ) async {
    if (state.actionStatus == NotificationCenterActionStatus.processing) {
      return;
    }
    if (state.unreadCount == 0) return;

    emit(
      state.copyWith(
        actionStatus: NotificationCenterActionStatus.processing,
        clearActionFailure: true,
      ),
    );
    final readAt = DateTime.now().toUtc();
    final result = await markAllNotificationsAsRead(
      organizationId: state.organizationId,
      userId: state.userId,
      readAt: readAt,
    );
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess<void>():
        emit(
          state.copyWith(
            actionStatus: NotificationCenterActionStatus.idle,
            notifications: <AppNotification>[
              for (final notification in state.notifications)
                _withReadAt(notification, readAt),
            ],
            clearActionFailure: true,
          ),
        );
      case AppFailure<void>(failure: final failure):
        emit(
          state.copyWith(
            actionStatus: NotificationCenterActionStatus.failure,
            actionFailure: failure,
          ),
        );
    }
  }

  void _onActionDismissed(
    NotificationCenterActionDismissed event,
    Emitter<NotificationCenterState> emit,
  ) {
    emit(
      state.copyWith(
        actionStatus: NotificationCenterActionStatus.idle,
        clearActionFailure: true,
      ),
    );
  }

  AppNotification _withReadAt(AppNotification notification, DateTime readAt) {
    if (notification.readAt != null) return notification;
    return AppNotification(
      id: notification.id,
      organizationId: notification.organizationId,
      userId: notification.userId,
      category: notification.category,
      title: notification.title,
      body: notification.body,
      deepLink: notification.deepLink,
      createdAt: notification.createdAt,
      readAt: readAt,
      priority: notification.priority,
      deliverAt: notification.deliverAt,
      customerId: notification.customerId,
    );
  }
}
