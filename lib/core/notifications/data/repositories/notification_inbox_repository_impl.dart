import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../../errors/errors.dart';
import '../../../utils/utils.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_inbox_repository.dart';
import '../datasources/notification_data_source.dart';
import '../local/notification_inbox_local_cache.dart';
import '../mappers/notification_mapper.dart';

/// [NotificationInboxRepository] backed by Firestore
/// (`organizations/{organizationId}/notifications`) as the source of truth,
/// with [NotificationInboxLocalCache] serving reads whenever the remote
/// fetch fails (offline, most commonly) and mirroring every write so the
/// cache never drifts far from what was last synced.
///
/// [create]/[markAsRead]/[markAllAsRead] all write the local cache first —
/// several callers (e.g. `ProcessTargetAlertUseCase`) must keep working
/// with no connectivity — then push the same change to Firestore
/// best-effort: a failed remote write is swallowed (logged nowhere yet; see
/// TASK-151's known-risks doc) instead of surfacing as a failure, since the
/// local write already satisfied the caller and a background/next-sync
/// mechanism is out of this task's scope (there is no outbox for
/// notifications, unlike orders).
@LazySingleton(as: NotificationInboxRepository)
final class NotificationInboxRepositoryImpl
    implements NotificationInboxRepository {
  const NotificationInboxRepositoryImpl(
    this._remote,
    this._localCache,
    this._mapper,
  );

  final NotificationDataSource _remote;
  final NotificationInboxLocalCache _localCache;
  final NotificationMapper _mapper;

  @override
  Future<AppResult<AppNotification>> create({
    required AppNotification notification,
  }) async {
    try {
      final current = await _localCache.load(
        organizationId: notification.organizationId,
        userId: notification.userId,
      );
      await _localCache.save(
        organizationId: notification.organizationId,
        userId: notification.userId,
        notifications: <AppNotification>[notification, ...current],
      );
    } catch (exception) {
      return AppFailure<AppNotification>(
        UnexpectedFailure(
          'Unexpected error saving internal notification locally.',
          code: 'notification_inbox_create_unexpected',
          cause: exception,
        ),
      );
    }

    unawaited(_syncCreateToRemote(notification));
    return AppSuccess<AppNotification>(notification);
  }

  @override
  Future<AppResult<List<AppNotification>>> listForUser({
    required String organizationId,
    required String userId,
  }) async {
    try {
      final dtos = await _remote.listForUser(
        organizationId: organizationId,
        userId: userId,
        limit: kNotificationInboxRetentionLimit,
      );
      final remote = dtos.map(_mapper.toEntity).toList(growable: false);
      final local = await _localCache.load(
        organizationId: organizationId,
        userId: userId,
      );
      final merged = _mergeNewestFirst(remote, local);
      await _localCache.save(
        organizationId: organizationId,
        userId: userId,
        notifications: merged,
      );
      return AppSuccess<List<AppNotification>>(_visibleOnly(merged));
    } catch (exception) {
      // Offline (or any remote failure): the notification center must stay
      // usable with whatever was last synced, rather than surface an error.
      final cached = await _localCache.load(
        organizationId: organizationId,
        userId: userId,
      );
      if (cached.isNotEmpty) {
        return AppSuccess<List<AppNotification>>(_visibleOnly(cached));
      }
      return AppFailure<List<AppNotification>>(
        exception is AppException
            ? mapAppExceptionToFailure(exception)
            : UnexpectedFailure(
                'Unexpected error loading internal notifications.',
                code: 'notification_inbox_list_unexpected',
                cause: exception,
              ),
      );
    }
  }

  @override
  Future<AppResult<void>> markAsRead({
    required String organizationId,
    required String userId,
    required String notificationId,
    DateTime? readAt,
  }) async {
    final instant = (readAt ?? DateTime.now()).toUtc();
    try {
      final current = await _localCache.load(
        organizationId: organizationId,
        userId: userId,
      );
      final updated = <AppNotification>[
        for (final notification in current)
          if (notification.id == notificationId)
            _markRead(notification, instant)
          else
            notification,
      ];
      await _localCache.save(
        organizationId: organizationId,
        userId: userId,
        notifications: updated,
      );
    } catch (exception) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Unexpected error marking notification as read locally.',
          code: 'notification_inbox_mark_read_unexpected',
          cause: exception,
        ),
      );
    }

    unawaited(
      _syncMarkAsReadToRemote(
        organizationId: organizationId,
        notificationId: notificationId,
        readAt: instant,
      ),
    );
    return const AppSuccess<void>(null);
  }

  @override
  Future<AppResult<void>> markAllAsRead({
    required String organizationId,
    required String userId,
    DateTime? readAt,
  }) async {
    final instant = (readAt ?? DateTime.now()).toUtc();
    List<String> unreadIds;
    try {
      final current = await _localCache.load(
        organizationId: organizationId,
        userId: userId,
      );
      // Never marks a notification still suppressed by quiet hours
      // (TASK-155) as read before it has even become visible to the
      // recipient — "marcar todas como lidas" only ever applies to what is
      // actually shown right now (`_visibleOnly`'s same instant).
      unreadIds = <String>[
        for (final notification in current)
          if (notification.readAt == null && notification.isVisibleAt(instant))
            notification.id,
      ];
      final updated = <AppNotification>[
        for (final notification in current)
          if (notification.readAt == null && notification.isVisibleAt(instant))
            _markRead(notification, instant)
          else
            notification,
      ];
      await _localCache.save(
        organizationId: organizationId,
        userId: userId,
        notifications: updated,
      );
    } catch (exception) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Unexpected error marking notifications as read locally.',
          code: 'notification_inbox_mark_all_read_unexpected',
          cause: exception,
        ),
      );
    }

    if (unreadIds.isNotEmpty) {
      unawaited(
        _syncMarkAllAsReadToRemote(
          organizationId: organizationId,
          ids: unreadIds,
          readAt: instant,
        ),
      );
    }
    return const AppSuccess<void>(null);
  }

  Future<void> _syncCreateToRemote(AppNotification notification) async {
    try {
      await _remote.create(_mapper.toDto(notification));
    } catch (_) {
      // Best-effort: the local write already succeeded, and this
      // notification's remote copy will simply be missing until a future
      // successful `listForUser` merge (or a later retry mechanism).
    }
  }

  Future<void> _syncMarkAsReadToRemote({
    required String organizationId,
    required String notificationId,
    required DateTime readAt,
  }) async {
    try {
      await _remote.markAsRead(
        organizationId: organizationId,
        id: notificationId,
        readAt: readAt,
      );
    } catch (_) {
      // Best-effort only — see class doc.
    }
  }

  Future<void> _syncMarkAllAsReadToRemote({
    required String organizationId,
    required List<String> ids,
    required DateTime readAt,
  }) async {
    try {
      await _remote.markAllAsRead(
        organizationId: organizationId,
        ids: ids,
        readAt: readAt,
      );
    } catch (_) {
      // Best-effort only — see class doc.
    }
  }

  AppNotification _markRead(AppNotification notification, DateTime readAt) {
    return AppNotification(
      id: notification.id,
      organizationId: notification.organizationId,
      userId: notification.userId,
      category: notification.category,
      title: notification.title,
      body: notification.body,
      deepLink: notification.deepLink,
      createdAt: notification.createdAt,
      readAt: notification.readAt ?? readAt,
      priority: notification.priority,
      deliverAt: notification.deliverAt,
      customerId: notification.customerId,
    );
  }

  /// Hides every notification still suppressed by the recipient's own quiet
  /// hours (TASK-155) — `AppNotification.deliverAt` still in the future at
  /// the moment this is called. Applied to both the remote-backed and the
  /// offline-cached result, so a notification generated during quiet hours
  /// (already durably persisted, never lost) simply becomes visible the
  /// next time this method runs after quiet hours end, without any separate
  /// delivery/flush job ever needing to run.
  List<AppNotification> _visibleOnly(List<AppNotification> notifications) {
    final now = DateTime.now().toUtc();
    return notifications
        .where((notification) => notification.isVisibleAt(now))
        .toList(growable: false);
  }

  /// Remote is the source of truth for anything it already knows about;
  /// any local-only entry (created fully offline and not yet synced) is
  /// kept too, so nothing created in the field ever silently disappears
  /// from the list before its first successful sync.
  List<AppNotification> _mergeNewestFirst(
    List<AppNotification> remote,
    List<AppNotification> local,
  ) {
    final remoteIds = remote.map((notification) => notification.id).toSet();
    final localOnly = local.where(
      (notification) => !remoteIds.contains(notification.id),
    );
    final combined = <AppNotification>[...remote, ...localOnly]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return combined.length > kNotificationInboxRetentionLimit
        ? combined.sublist(0, kNotificationInboxRetentionLimit)
        : combined;
  }
}
